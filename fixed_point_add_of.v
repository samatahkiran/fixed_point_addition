`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.05.2024 15:35:29
// Design Name: 
// Module Name: fixed_point_add_of
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fixed_point_add_of#(
                   
                       parameter int_bits_A1 = 3,
    parameter frac_bits_F1 = 14,
    parameter int_bits_A2 = 3,
    parameter frac_bits_F2 = 14,
    parameter int_bits_out = 4,
    parameter frac_bits_out = 14,
    parameter greater_int = (int_bits_A1 >= int_bits_A2)?int_bits_A1:int_bits_A2,
    parameter greater_frac = (frac_bits_F1 >= frac_bits_F2)?frac_bits_F1:frac_bits_F2)(
    input wire clk,
    input wire rst,
    input wire signed [int_bits_A1 + frac_bits_F1 - 1 : 0] A,
    input wire signed [int_bits_A2 + frac_bits_F2 - 1 : 0] B,
    output reg signed [int_bits_out + frac_bits_out - 1 : 0] sum,
    output reg overflow
);

    // Internal registers
    reg signed [greater_int + greater_frac - 1 : 0] temp_A;
    reg signed [greater_int + greater_frac - 1 : 0] temp_B;
    reg signed [greater_int + greater_frac : 0] temp_out;

    // Separating integer part and fractional part
    reg signed [int_bits_A1 - 1 : 0] A_Int;
    reg [frac_bits_F1 - 1 : 0] A_Frac;
    reg signed [int_bits_A2 - 1 : 0] B_Int;
    reg [frac_bits_F2 - 1 : 0] B_Frac;

    // Sign extension
    reg signed [greater_int - 1 : 0] tempA_Int;
    reg signed [greater_int - 1 : 0] tempB_Int;
    reg [greater_frac - 1 : 0] tempA_Frac;
    reg [greater_frac - 1 : 0] tempB_Frac;

    //Separating Integer and Fractional Parts

    always @(posedge clk) begin
        if (rst) begin
            A_Int <= 0;
            A_Frac <= 0;
            B_Int <= 0;
            B_Frac <= 0;
        end else begin
            A_Int <= A[int_bits_A1 + frac_bits_F1 - 1 : frac_bits_F1];
            A_Frac <= A[frac_bits_F1 - 1 : 0];
            B_Int <= B[int_bits_A2 + frac_bits_F2 - 1 : frac_bits_F2];
            B_Frac <= B[frac_bits_F2 - 1 : 0];
        end
    end
   //Sign Extension


    always @(posedge clk) begin
        if (rst) begin
            tempA_Int <= 0;
            tempB_Int <= 0;
        end else if (int_bits_A1 > int_bits_A2) begin
            tempA_Int <= A_Int;
            tempB_Int <= {{(int_bits_A1 - int_bits_A2){B_Int[int_bits_A2 - 1]}}, B_Int};
        end else begin
            tempA_Int <= {{(int_bits_A2 - int_bits_A1){A_Int[int_bits_A1 - 1]}}, A_Int};
            tempB_Int <= B_Int;
        end
    end
   //Zero Padding for Fractional Parts

    always @(posedge clk) begin
        if (rst) begin
            tempA_Frac <= 0;
            tempB_Frac <= 0;
        end else if (frac_bits_F1 > frac_bits_F2) begin
            tempB_Frac <= {B_Frac, {(frac_bits_F1 - frac_bits_F2){1'b0}}};
            tempA_Frac <= A_Frac;
        end else begin
            tempA_Frac <= {A_Frac, {(frac_bits_F2 - frac_bits_F1){1'b0}}};
            tempB_Frac <= B_Frac;
        end
    end

    // Addition
    always @(posedge clk) begin
        if (rst) begin
            temp_A <= 0;
            temp_B <= 0;
        end else begin
            temp_A <= {tempA_Int, tempA_Frac};
            temp_B <= {tempB_Int, tempB_Frac};
        end
    end


    always @(posedge clk) begin
        if (rst) begin
            temp_out <= 0;
        end else begin
            temp_out <= temp_A + temp_B;
        end
    end
 
   // Adjust for the output fraction bits
    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
        end else begin
            sum <= temp_out >>> (greater_frac - frac_bits_out); // Adjust for the output fraction bits
        end
    end

    // Overflow Detection
    always @(posedge clk) begin
        if (rst) begin
            overflow <= 0;
        end else begin
             overflow <= (temp_A[greater_int + greater_frac - 1] == temp_B[greater_int + greater_frac - 1]) &&
                        (temp_out[greater_int + greater_frac] != temp_A[greater_int + greater_frac - 1]);
        end
    end
 endmodule