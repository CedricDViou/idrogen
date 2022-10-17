// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// Generated by Quartus Prime Version 18.1.0 Build 222 09/21/2018 SJ Pro Edition
// Created on Fri Feb 18 19:44:24 2022

// synthesis message_off 10175

//`timescale 1ns/1ns

module SPI_interface (
    input  wire         clk,	                //! Signal d'horloge
	input  wire         nreset, 		        //! Signal de Reset (actif a l'etat bas)
	// SPI Interface
	input  wire         csn,			        //! Chip select
	input  wire         spi_clk,		        //! Horloge SPI
	input  wire         mosi,			        //! Signal SPI mosi
    input  wire	        acknowledge,            //! Signal d'acknoledge provenant du bus avalon pour signaler que l'operation de lecture/ecriture est terminee.
    input  wire [31:0]  read_data_from_avallon, //! Donnee de lecture a transmettre au processus SPI

    output wire         miso,			        //! Signal SPI miso
    output wire 		read,                   //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation de lecture
    output wire			write,                  //! Signal positionne a "1" pour indiquer au bus avallon que l'on souhaite realiser une operation d'ecriture
    output wire  [3:0] 	byte_enable,            //! Indique les octets a lire/ecrire dans le mot de 32 bits
    output wire [31:0] 	address,				//! Adresse de lecture/ecriture sur le bus avallon
    output wire [31:0] 	write_data_to_avallon   //! Donnee d'ecriture a transmettre a l'interface avallon
);

reg 		flag, release_flag;			//! Flag d'arrivee du signal "acknowledge"
reg 		mult_words;					//! Indique si l'on ecrit un mot sur l'adresse N+1
reg   [6:0] bit_cnt;					//! Compteur de bits de la trame SPI
reg  [31:0] sri, sro;					//! Registre a decalage
wire [31:0] tempo_data_spi;				//! Donnee latchee provenant du bus Avallon

assign miso = sro[31];

//! Machine d'etat d'interface entre la lecture de la trame SPI et l'envoi des donnees vers le bus Avallon
SPI_SM fsm_inst (
    .nreset					(nreset), 
    .clock					(clk), 
    .ack					(acknowledge), 
    .bit_cnt				(bit_cnt),
    .csn					(csn), 
//	.rw						(sri[31]), 
    .data_from_spi			(sri),
    .read_data_from_avallon (read_data_from_avallon),
    // outputs
    .read					(read), 
    .write					(write),
    .address				(address),
    .byte_enable			(byte_enable),
    .read_data_to_spi		(tempo_data_spi),
    .write_data_to_avallon	(write_data_to_avallon)
);

//! Processus "rapide" qui detecte l'arrivee du signal "acknowledge" pour savoir quand ecrire la donnee provenant du bus Avallon dans le registre a decalage de sortie du processus SPI.

//! Le registre "flag" est positionne a "1" quand le signal "acknowledge" est detecte et remis a zero une fois que la donnee est ecrite dans le registre a decalage.

//! Le registre "release_flag" est controle par le processus SPI et indique quand remettre a zero le registre "flag".

always @(posedge clk or negedge nreset or posedge release_flag) begin : avallon_rise_flag_process
    if (~nreset || release_flag) begin
        flag <= 1'b0;
    end
    else begin
        if (acknowledge) begin
            flag <= 1'b1;
        end
        else begin
            flag <= flag;
        end
    end
end

//! Le registre "release_flag" est positionne a "1" une fois que la donnee est ecrite dans le registre a decalage de sortie.

//! Quand le registre "flag" est positionne a la valeur "1", la valeur du registre tampon "tempo_data_spi" peut etre ecrite dans le registre a decalage de sortie "sro". Sinon, le registre "sro" est decale d'un bit a chaque front descendant de l'horloge SPI. 

//!Le bus SPI miso transmet les bits du registre en allant du bit de poids fort au bit de poids faible.

//! Lorsque l'on ecrit la valeur du registre tampon "tempo_data_spi" dans le registre a decalage, on inverse l'ordre des octets.

always @(negedge spi_clk or negedge nreset or posedge csn) begin : spi_writing_process
    if (~nreset || csn) begin
        sro 			<= 32'b0;
        release_flag 	<=  1'b0;
    end
    else if (flag) begin
        release_flag 	<= 1'b1;
//		sro 			<= tempo_data_spi;
        sro 			<= {tempo_data_spi[7:0], tempo_data_spi[15:8], tempo_data_spi[23:16], tempo_data_spi[31:24]};
    end
    else begin
        release_flag 	<= 1'b0;
//		sro 			<= {1'b0, sro[31:1]};
        sro 			<= {sro[30:0], 1'b0};
    end
end

//! Ce processus permet de realiser l'operation de decalage du registre d'entree "sri" par concatenation des bits provenant du bus "mosi".

//! Le registre "bit_cnt" permet de compter le nombre de bits recus ou a transmettre. Il permet de delimiter la fin de la lecture de l'adresse et le debut de la reception ou de la transmission de la donnee.

//! Lorsque les 32 premiers bits sont recus, on stock la valeur du registre a decalage d'entree "sri" dans le registre "address". Sur ces 32 bits, l'adresse est codee sur les 31 premiers bits, le bit de poid fort correspond a l'operation a effectuer (1 : lecture, 0 : ecriture). 

//! Dans certain cas, plusieurs mots de 32-bits peuvent etre recu a la suite, c-a-d pour une seule valeure d'adresse recue. Cela signifie que l'on souhaite ecrire les donnees dans des adresses successives a partir de l'adresse recue. On incremente donc la valeur du registre "address" apres chaque donnee

always @(posedge spi_clk or negedge nreset or posedge csn) begin : spi_reading_process
    if (~nreset || csn) begin
        mult_words	<=  1'b0;
        bit_cnt 	<=  7'h0;
        sri 		<= 32'b0;
//		address 	<= 32'b0;
    end
    else begin
        bit_cnt	<= bit_cnt + 7'h1;
        sri 	<= {sri[30:0], mosi};
        if (bit_cnt==7'h40) begin
            bit_cnt 	<= 7'h20;
            mult_words 	<= 1'b1;
        end
    end
end

endmodule
