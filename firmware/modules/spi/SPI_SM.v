//! State Machine interface between SPI slave module and Avalon External Bus

module SPI_SM (
    input  wire        nreset,                 //! Reset actif a l'etat bas
    input  wire        clock,                  //! Horloge
    input  wire        ack,                    //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
    input  wire        csn,                    //! Chip select
    input  wire [ 6:0] bit_cnt,                //! Position dans la trame SPI
    input  wire [31:0] read_data_from_avalon,  //! Donnee recue du bus avalon
    input  wire [31:0] data_from_spi,          //! Donnee recue du bus SPI
    output reg         read,                   //! Signal positionne a "1" pour indiquer au bus avalon que l'on souhaite realiser une operation de lecture
    output reg         write,                  //! Signal positionne a "1" pour indiquer au bus avalon que l'on souhaite realiser une operation d'ecriture
    output reg  [ 3:0] byte_enable,            //! Indique les octets a lire/ecrire dans le mot de 32 bits
    output reg  [31:0] read_data_to_spi,       //! Donnee de lecture a transmettre au processus SPI
    output reg  [31:0] write_data_to_avalon,   //! Donnee d'ecriture a transmettre a l'interface avalon
    output reg  [31:0] address                 //! Adresse de lecture/ecriture sur le bus avalon
);
    
    reg         wait_flag;
    reg         ack_synchro;                    
    reg  [6:0]  reg_fstate;                     //! Registre d'etat
    reg  [6:0]  bit_cnt_synchro;                //! Resynchronisation du registre bit_cnt
    reg [31:0]  data_from_spi_synchro;          //! Resynchronisation du registre data_from_spi
    reg [31:0]  read_data_from_avalon_synchro;  //! Resynchronisation du registre read_data_from_avalon

    //! Resynchronisation des signaux d'entree sur le nouveau domaine d'horloge
    always @(posedge clock or negedge nreset or posedge csn)
    begin : sync_prosses
        if (~nreset || csn) begin
            ack_synchro                     <=  1'b0;
            bit_cnt_synchro                 <=  7'd0;
            data_from_spi_synchro           <= 32'h0;
            read_data_from_avalon_synchro   <= 32'h0;
        end
        else begin
            ack_synchro                     <= ack;
            bit_cnt_synchro                 <= bit_cnt;
            data_from_spi_synchro           <= data_from_spi;
            read_data_from_avalon_synchro   <= read_data_from_avalon;
        end
    end
    
    localparam IDLE                 =  7'd0;
    localparam GET_ADDRESS          =  7'd1;
    localparam READ_AVALON          =  7'd2;
    localparam SEND_SPI             =  7'd4;
    localparam WAIT_READ_END_FRAME  =  7'd8;
    localparam GET_SPI              = 7'd16;
    localparam WRITE_AVALON         = 7'd32;
    localparam WAIT_WRITE_END_FRAME = 7'd64;
    
    //! State Machine process : update state
    //! fsm_extract
    always @(posedge clock or negedge nreset or posedge csn)
    begin : state_machine_interface
        if (~nreset || csn) begin
            reg_fstate [6:0]        <=  IDLE;
            read                    <=  1'b0;
            write                   <=  1'b0;
            wait_flag               <=  1'b0;
            byte_enable             <=  4'h0;
            address                 <= 32'h0;
            read_data_to_spi        <= 32'h0;
            write_data_to_avalon    <= 32'h0;
        end
        else begin
            case (reg_fstate)
                IDLE: begin
                    reg_fstate [6:0]        <=  GET_ADDRESS;    // Sortie de l'etat IDLE et debut de la lecture de l'adresse
                    read                    <=  1'b0;
                    write                   <=  1'b0;
                    byte_enable             <=  4'h0;
                    address                 <= 32'h0;
                    read_data_to_spi        <= 32'h0;
                    write_data_to_avalon    <= 32'h0;
                end
                GET_ADDRESS: begin    
                    if (bit_cnt_synchro==7'h20) begin
                        address [31:0]          <= {1'b0, data_from_spi_synchro[30:0]};
                        if (data_from_spi_synchro[31])
                            reg_fstate [6:0]    <= READ_AVALON; // L'adresse est recue et on commence la lecture du bus avalon
                        else
                            reg_fstate [6:0]    <= GET_SPI;     // L'adresse est recue et on commence la reception de la donnee a ecrire
                    end
                    else begin
                        reg_fstate [6:0]    <= reg_fstate;
                        address             <= address; 
                    end
                end
                READ_AVALON: begin
                    // Operation de lecture : les registres "read" et "byte_enable" sont actif pour lancer la lecture au niveau du bus avalon
                    read        <= 1'b1;
                    byte_enable <= 4'hF;
                    // Le signal "acknoledge" est arrive, la lecture est terminee, on latch la donnee provenant du bus avalon pour la transmettre au bus SPI. 
                    if (ack_synchro) begin                      
                        reg_fstate [6:0]        <= SEND_SPI;
                        read_data_to_spi[31:0]  <= read_data_from_avalon_synchro[31:0];
                        read                    <= 1'b0;            
                        byte_enable             <= 4'h0;
                    end
                    else begin
                        reg_fstate [6:0]    <= reg_fstate;
                        read_data_to_spi    <= read_data_to_spi;
                    end
                end
                SEND_SPI: begin
                    // La lecture est terminee, les registres "read" et "byte_enable" sont remis a zero. On commence la transmission des donnees par le bus SPI. On attend le 64ieme bit pour passer a l'etat suivant.
                    if (bit_cnt_synchro==7'h40) begin
                        if(wait_flag==1'b0)
                            reg_fstate [6:0]    <= WAIT_READ_END_FRAME;
                        else
                            reg_fstate [6:0]    <= reg_fstate;
                    end
                    else begin
                        wait_flag           <= 1'b0;
                        reg_fstate [6:0]    <= reg_fstate;
                    end
                end
                WAIT_READ_END_FRAME: begin
                    // Le signal "csn" indique la fin de la trame, on retourne a l'etat IDLE
                    // Si l'on souhaite lire plusieurs donnees, on retourne a l'etat de demande de lecture au bus avalon
                    if (csn)
                        reg_fstate [6:0]    <= IDLE;
                    else begin
                        reg_fstate [6:0]    <= READ_AVALON;
                        address             <= address + 32'h4;
                        wait_flag           <= 1'b1;
                    end
                end
                GET_SPI: begin
                    // Debut de la reception de la donnee a ecrire en provenance du bus SPI. On attend le 64ieme bit pour passer a l'etat suivant : l'ecriture dans la memoire via le bus avalon.
                    if (bit_cnt_synchro==7'h40) begin
                        if (wait_flag==1'b0)
                            reg_fstate [6:0]    <= WRITE_AVALON;
                        else
                            reg_fstate [6:0]    <= reg_fstate;
                    end
                    else begin
                        wait_flag           <= 1'b0;
                        reg_fstate [6:0]    <= reg_fstate;
                    end
                end
                WRITE_AVALON: begin
                    // Fin de la reception de la donnee, les registres "write" et "byte_enable" sont actif pour commencer l'operation d'ecriture.
                    // On inverse les octets de la donnee recue via le SPI
                    write                   <= 1'b1;
                    byte_enable             <= 4'hF;
                    write_data_to_avalon    <= {data_from_spi_synchro[7:0], data_from_spi_synchro[15:8], data_from_spi_synchro[23:16], data_from_spi_synchro[31:24]};
                    if (ack_synchro) begin
                        reg_fstate [6:0]    <= WAIT_WRITE_END_FRAME;
                        write               <= 1'b0;
                        byte_enable         <= 4'h0;
                    end
                    else
                        reg_fstate [6:0]    <= reg_fstate;
                end
                WAIT_WRITE_END_FRAME: begin
                    // Le signal "csn" indique la fin de la trame, on retourne a l'etat IDLE
                    // Si l'on souhaite ecrire plusieurs donnees, on retourne a l'etat d'attente de la reception de la donnee SPI
                    if (csn)
                        reg_fstate [6:0]    <= IDLE;
                    else begin
                        reg_fstate [6:0]    <= GET_SPI;
                        address             <= address + 32'h4;
                        wait_flag           <= 1'b1;
                    end
                end
                default: begin
                    reg_fstate [6:0] <= IDLE;
                end
            endcase
        end
    end
endmodule
