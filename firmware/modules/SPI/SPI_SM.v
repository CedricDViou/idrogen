module SPI_SM (
    nreset, clock, ack, bit_cnt[6:0], csn, read_data_from_avallon[31:0], data_from_spi[31:0],
    address[31:0], read, write, byte_enable[3:0], read_data_to_spi[31:0], write_data_to_avallon[31:0]);

    input 			nreset;                 //! Reset actif a l'etat bas
    input 			clock;                  //! Horloge
    input 			ack;                    //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
    input 			csn;                    //! Chip select
	input  [6:0] 	bit_cnt;                //! Position dans la trame SPI
    input [31:0] 	read_data_from_avallon; //! Donnee recue du bus avallon
    input [31:0] 	data_from_spi;    		//! Donnee recue du bus SPI
	
    tri0 		nreset;
    tri0 		ack;
    tri0 		csn;
	tri0  [6:0] bit_cnt;
    tri0 [31:0] read_data_from_avallon;
    tri0 [31:0] data_from_spi;
	
    output reg 			read;                   //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation de lecture
    output reg			write;                  //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation d'ecriture
    output reg  [3:0] 	byte_enable;            //! Indique les octets a lire/ecrire dans le mot de 32 bits
    output reg [31:0] 	read_data_to_spi;       //! Donnee de lecture a transmettre au processus SPI
    output reg [31:0] 	write_data_to_avallon;  //! Donnee d'ecriture a transmettre a l'interface avallon
	output reg [31:0] 	address;				//! Adresse de lecture/ecriture sur le bus avallon
	
    reg         wait_flag;
	reg  [6:0] 	reg_fstate;                     //! Registre d'etat
    
    reg 		ack_synchro;                    
	reg  [6:0] 	bit_cnt_synchro;                //! Resynchronisation du registre bit_cnt
    reg [31:0] 	data_from_spi_synchro;    		//! Resynchronisation du registre data_from_spi
    reg [31:0] 	read_data_from_avallon_synchro; //! Resynchronisation du registre read_data_from_avallon

    //! Resynchronisation des signaux d'entree sur le nouveau domaine d'horloge
    always @(posedge clock or negedge nreset or posedge csn)
    begin : sync_prosses
        if (~nreset || csn) begin
            ack_synchro 					<=  1'b0;
            bit_cnt_synchro      		    <=  7'd0;
			data_from_spi_synchro 		    <= 32'h0;
            read_data_from_avallon_synchro 	<= 32'h0;
        end
        else begin
            ack_synchro 					<= ack;
            bit_cnt_synchro      		    <= bit_cnt;
			data_from_spi_synchro 		    <= data_from_spi;
            read_data_from_avallon_synchro 	<= read_data_from_avallon;
        end
    end
	
	// IDLE 				= 7'd0
	// GET ADDRESS 			= 7'd1
	// READ_AVALON 			= 7'd2
	// SEND_SPI				= 7'd4
    // WAIT_READ_END_FRAME 	= 7'd8
	// GET_SPI				= 7'd16
	// WRITE_AVALON 		= 7'd32
	// WAIT_WRITE_END_FRAME = 7'd64
	
    //! State Machine process : update state
    //! fsm_extract
	always @(posedge clock or negedge nreset or posedge csn)
    begin : state_machine_interface
        if (~nreset || csn) begin
            reg_fstate [6:0]		<=  7'd0;
            read 					<=  1'b0;
            write 					<=  1'b0;
            wait_flag               <=  1'b0;
            byte_enable 			<=  4'h0;
            address 				<= 32'h0;
			read_data_to_spi 		<= 32'h0;
            write_data_to_avallon 	<= 32'h0;
        end
        else begin
            case (reg_fstate)
                7'd0: begin
					reg_fstate [6:0]		<=  7'd1;   // Sortie de l'etat IDLE et debut de la lecture de l'adresse
					read 					<=  1'b0;
					write 					<=  1'b0;
					byte_enable 			<=  4'h0;
					address 				<= 32'h0;
					read_data_to_spi 		<= 32'h0;
					write_data_to_avallon 	<= 32'h0;
                end
                7'd1: begin	
                    if (bit_cnt_synchro==7'h20) begin
                        address [31:0]	<= {1'b0, data_from_spi_synchro[30:0]};
                        if (data_from_spi_synchro[31])
                            reg_fstate [6:0] 	<= 7'd2;    // L'adresse est recue et on commence la lecture du bus avallon
                        else
                            reg_fstate [6:0] 	<= 7'd16;   // L'adresse est recue et on commence la reception de la donnee a ecrire
                    end
                    else begin
                        reg_fstate [6:0] 	<= reg_fstate;
                        address             <= address; 
					end
                end
                7'd2: begin
                    // Operation de lecture : les registres "read" et "byte_enable" sont actif pour lancer la lecture au niveau du bus avallon
					read 		<= 1'b1;
					byte_enable <= 4'hF;
                    // Le signal "acknoledge" est arrive, la lecture est terminee, on latch la donnee provenant du bus avallon pour la transmettre au bus SPI. 
                    if (ack_synchro) begin                      
                        reg_fstate [6:0]		<= 7'd4;
						read_data_to_spi[31:0] 	<= read_data_from_avallon_synchro[31:0];
                        read 		            <= 1'b0;            
					    byte_enable             <= 4'h0;
					end
                    else begin
                        reg_fstate [6:0]	<= reg_fstate;
						read_data_to_spi 	<= read_data_to_spi;
					end
                end
                7'd4: begin
                    // La lecture est terminee, les registres "read" et "byte_enable" sont remis a zero. On commence la transmission des donnees par le bus SPI. On attend le 64ieme bit pour passer a l'etat suivant.
                    if (bit_cnt_synchro==7'h40) begin
                        if(wait_flag==1'b0)
                            reg_fstate [6:0] 	<= 7'd8;
                        else
                            reg_fstate [6:0] 	<= reg_fstate;
                    end
                    else begin
                        wait_flag           <= 1'b0;
                        reg_fstate [6:0] 	<= reg_fstate;
                    end
                end
                7'd8: begin
                    // Le signal "csn" indique la fin de la trame, on retourne a l'etat IDLE
                    // Si l'on souhaite lire plusieurs donnees, on retourne a l'etat de demande de lecture au bus avallon
					if (csn)
						reg_fstate [6:0] 	<= 7'd0;
                    else begin
						reg_fstate [6:0] 	<= 7'd2;
						address 			<= address + 32'h4;
                        wait_flag           <= 1'b1;
					end
				end
                7'd16: begin
                    // Debut de la reception de la donnee a ecrire en provenance du bus SPI. On attend le 64ieme bit pour passer a l'etat suivant : l'ecriture dans la memoire via le bus avallon.
                    if (bit_cnt_synchro==7'h40) begin
                        if (wait_flag==1'b0)
                            reg_fstate [6:0] 	<= 7'd32;
                        else
                            reg_fstate [6:0] 	<= reg_fstate;
                    end
                    else begin
                        wait_flag           <= 1'b0;
                        reg_fstate [6:0] 	<= reg_fstate;
                    end
                end
                7'd32: begin
                    // Fin de la reception de la donnee, les registres "write" et "byte_enable" sont actif pour commencer l'operation d'ecriture.
                    // On inverse les octets de la donnee recue via le SPI
					write 					<= 1'b1;
					byte_enable 			<= 4'hF;
					write_data_to_avallon 	<= {data_from_spi_synchro[7:0], data_from_spi_synchro[15:8], data_from_spi_synchro[23:16], data_from_spi_synchro[31:24]};
                    if (ack_synchro) begin
                        reg_fstate [6:0] 	<= 7'd64;
                        write 				<= 1'b0;
					    byte_enable 		<= 4'h0;
                    end
                    else
                        reg_fstate [6:0] 	<= reg_fstate;
                end
				7'd64: begin
                    // Le signal "csn" indique la fin de la trame, on retourne a l'etat IDLE
                    // Si l'on souhaite ecrire plusieurs donnees, on retourne a l'etat d'attente de la reception de la donnee SPI
					if (csn)
						reg_fstate [6:0] 	<= 7'd0;
                    else begin
						reg_fstate [6:0] 	<= 7'd16;
						address 			<= address + 32'h4;
                        wait_flag           <= 1'b1;
					end
				end
                default: begin
					reg_fstate [6:0] 		<= 7'd0;
                end
            endcase
        end
    end
endmodule
