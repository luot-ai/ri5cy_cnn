// Description:    Custom cnn processor unit

 cv32e40p_ccpu
import cv32e40p_pkg::*;
(
    input logic clk,
    input logic rst_n,
    //rdata
    input logic [127:0] ccvec_rdata_a,
    input logic [127:0] ccvec_rdata_b,
    input logic [127:0] ccvec_rdata_c,
    //wdest wmask encode
    input logic [3:0]    ccvec_wdest_i,
    input logic [3:0]    ccvec_wmask_i,
    input logic [2:0]    ccist_encode_i,//aamul:4 triadd:2 oacc:2
    output logic [127:0] ccvec_wdata_o,    
    output logic [3:0]   ccvec_wmask_o,  
    output logic [3:0]   ccvec_wdest_o,    
    //selector
    input logic        cus_add1_4_up,
    input logic        cus_add1_1_down,
    input logic [1:0]  cus_add1_2_down,
    input logic [1:0]  cus_add1_3_down,
    input logic [1:0]  cus_add1_4_down,
    input logic        cus_add2_1_up,
    input logic        cus_add2_2_up,
    input logic        cus_add2_3_up,
    input logic        cus_add2_4_up,
    input logic [1:0]  cus_add2_1_down,
    input logic        cus_add2_2_down,
    input logic [1:0]  cus_add2_3_down,
    input logic        cus_add2_4_down,
    //ready valid 
    input  logic ccpu_valid_i, 
    input  logic ccpu_ready_o,
    output logic ccpu_valid_o,
    output logic ccpu_ready_i
);

//stage1
logic [31:0] rdata_a_0;
logic [31:0] rdata_a_1;
logic [31:0] rdata_a_2;
logic [31:0] rdata_a_3;
logic [31:0] rdata_b_0;
logic [31:0] rdata_b_1;
logic [31:0] rdata_b_2;
logic [31:0] rdata_b_3;
logic [31:0] rdata_c_0;
logic [31:0] rdata_c_1;
logic [31:0] rdata_c_2;
logic [31:0] rdata_c_3;

logic [31:0] add1_1_up;
logic [31:0] add1_2_up;
logic [31:0] add1_3_up;
logic [31:0] add1_4_up;
logic [31:0] add1_1_down;
logic [31:0] add1_2_down;
logic [31:0] add1_3_down;
logic [31:0] add1_4_down;

logic [31:0] add2_1_up;
logic [31:0] add2_2_up;
logic [31:0] add2_3_up;
logic [31:0] add2_4_up;
logic [31:0] add2_1_down;
logic [31:0] add2_2_down;
logic [31:0] add2_3_down;
logic [31:0] add2_4_down;

logic [31:0] a1_o0;
logic [31:0] a1_o1;
logic [31:0] a1_o2;
logic [31:0] a1_o3;


//stage2
reg        cus_add2_1_up_stage2;
reg        cus_add2_2_up_stage2;
reg        cus_add2_3_up_stage2;
reg        cus_add2_4_up_stage2;
reg [1:0]  cus_add2_1_down_stage2;
reg        cus_add2_2_down_stage2;
reg [1:0]  cus_add2_3_down_stage2;
reg        cus_add2_4_down_stage2;

reg [31:0] a1_o0_stage2;
reg [31:0] a1_o1_stage2;
reg [31:0] a1_o2_stage2;
reg [31:0] a1_o3_stage2;

reg [31:0] rdata_c_0_stage2;
reg [31:0] rdata_c_1_stage2;
reg [31:0] rdata_c_2_stage2;
reg [31:0] rdata_c_3_stage2;

reg  [2:0]      ccist_encode_stage2;//aamul:4 triadd:2 oacc:2
reg  [3:0]      ccvec_wdest_stage2;    
reg  [3:0]      ccvec_wmask_stage2;  

logic [31:0] a2_o0;
logic [31:0] a2_o1;
logic [31:0] a2_o2;
logic [31:0] a2_o3;
logic [127:0] stage2_wdata;

//stage3
reg [31:0] a2_o0_stage3;
reg [31:0] a2_o1_stage3;
reg [31:0] a2_o2_stage3;
reg [31:0] a2_o3_stage3;
reg [31:0] rdata_c_0_stage3;
reg [31:0] rdata_c_1_stage3;
reg [31:0] rdata_c_2_stage3;
reg [31:0] rdata_c_3_stage3;
reg  [3:0] ccvec_wdest_stage3;    
reg  [3:0] ccvec_wmask_stage3;  

//stage4
reg  [3:0]  ccvec_wdest_stage4;    
reg  [3:0]  ccvec_wmask_stage4;  
logic [127:0] stage4_cal_data;

reg             tmp_hold_on;
reg  [3:0]      wdest_tmp_reg;    
reg  [3:0]      wmask_tmp_reg; 
reg  [127:0]    res_tmp_reg;

logic  [3:0]  stage4_wdest_o;    
logic  [3:0]  stage4_wmask_o;  
logic [127:0] stage4_wdata_o;

logic [63:0] m_o0;
logic [63:0] m_o1;
logic [63:0] m_o2;
logic [63:0] m_o3;

//valid-ready
reg valid_stage1;
reg valid_stage2;
reg valid_stage3;
reg valid_stage4;
logic ccpu_i_fire;
logic stage12_fire;
logic stage23_fire;
logic stage34_fire;
logic stage1_ready;
logic stage2_ready;
logic stage3_ready;
logic stage4_ready;
logic stage2_valid_to_stage3;
logic stage2_valid_o;
always @(posedge clk) begin
    if(!rst_n) begin
        valid_stage1<=0;
        valid_stage2<=0;
        valid_stage3<=0;
        valid_stage4<=0;
    end
    else begin
        valid_stage1<=ccpu_i_fire ||(valid_stage1 && !stage2_ready);
        valid_stage2<=stage12_fire||(valid_stage2 && !stage3_ready);
        valid_stage3<=stage23_fire||(valid_stage3 && !stage4_ready);
        valid_stage4<=stage34_fire||(valid_stage4 && !ccpu_ready_i);
    end
end
assign stage2_valid_o         = valid_stage2 && ccist_encode_stage2[2];
assign stage2_valid_to_stage3 = valid_stage2 && !ccist_encode_stage2[2];

assign stage4_ready = !valid_stage4 || ccpu_ready_i;
assign stage3_ready = !valid_stage3 || stage4_ready;
assign stage2_ready = !valid_stage2 || stage3_ready;
assign stage1_ready = !valid_stage1 || stage2_ready;

assign ccpu_i_fire = ccpu_ready_o && ccpu_valid_i;
assign stage12_fire= valid_stage1 && stage2_ready;
assign stage23_fire= stage2_valid_to_stage3 && stage3_ready;
assign stage34_fire= valid_stage3 && stage4_ready;

//stage1
assign rdata_a_0 = ccvec_rdata_a[31:0] ;
assign rdata_a_1 = ccvec_rdata_a[63:32] ;
assign rdata_a_2 = ccvec_rdata_a[95:64] ;
assign rdata_a_3 = ccvec_rdata_a[127:96] ;
assign rdata_b_0 = ccvec_rdata_b[31:0] ;
assign rdata_b_1 = ccvec_rdata_b[63:32] ;
assign rdata_b_2 = ccvec_rdata_b[95:64] ;
assign rdata_b_3 = ccvec_rdata_b[127:96] ;
assign rdata_c_0 = ccvec_rdata_c[31:0] ;
assign rdata_c_1 = ccvec_rdata_c[63:32] ;
assign rdata_c_2 = ccvec_rdata_c[95:64] ;
assign rdata_c_3 = ccvec_rdata_c[127:96] ;

assign add1_1_up = rdata_a_0;
assign add1_2_up = rdata_a_1;
assign add1_3_up = rdata_a_2;
assign add1_4_up = cus_add1_4_up?rdata_a_3:rdata_a_1;

assign add1_1_down = cus_add1_1_down?rdata_b_0:(~rdata_b_0+32'd1);
assign add1_2_down = cus_add1_2_down[1]?rdata_b_1:cus_add1_2_down[0]?(~rdata_b_1+32'd1):rdata_a_2;
assign add1_3_down = cus_add1_3_down[1]?rdata_b_2:cus_add1_3_down[0]?(~rdata_b_2+32'd1):rdata_a_3;
assign add1_4_down = cus_add1_4_down[1]?rdata_b_3:cus_add1_4_down[0]?(~rdata_b_3+32'd1):rdata_b_1;

assign a1_o0    =   add1_1_up   +   add1_1_down;
assign a1_o1    =   add1_2_up   +   add1_2_down;
assign a1_o2    =   add1_3_up   +   add1_3_down;
assign a1_o3    =   add1_4_up   +   add1_4_down;

//stage2

always @(posedge clk) begin
    if(!rst_n) begin
        cus_add2_1_up_stage2<=0;
        cus_add2_2_up_stage2<=0;
        cus_add2_3_up_stage2<=0;
        cus_add2_4_up_stage2<=0;
        cus_add2_1_down_stage2<=0;
        cus_add2_2_down_stage2<=0;
        cus_add2_3_down_stage2<=0;
        cus_add2_4_down_stage2<=0;
        a1_o0_stage2<=0;
        a1_o1_stage2<=0;
        a1_o2_stage2<=0;
        a1_o3_stage2<=0;
        rdata_c_0_stage2<=0;
        rdata_c_1_stage2<=0;
        rdata_c_2_stage2<=0;
        rdata_c_3_stage2<=0;
        ccist_encode_stage2<=0;//aamul:0-3 triadd:45 oacc:67
        ccvec_wdest_stage2<=0;    
        ccvec_wmask_stage2<=0;  
    end
    else if(stage12_fire) begin
        cus_add2_1_up_stage2<=cus_add2_1_up;
        cus_add2_2_up_stage2<=cus_add2_2_up;
        cus_add2_3_up_stage2<=cus_add2_3_up;
        cus_add2_4_up_stage2<=cus_add2_4_up;
        cus_add2_1_down_stage2<=cus_add2_1_down;
        cus_add2_2_down_stage2<=cus_add2_2_down;
        cus_add2_3_down_stage2<=cus_add2_3_down;
        cus_add2_4_down_stage2<=cus_add2_4_down;
        a1_o0_stage2<=a1_o0;
        a1_o1_stage2<=a1_o1;
        a1_o2_stage2<=a1_o2;
        a1_o3_stage2<=a1_o3;
        rdata_c_0_stage2<=rdata_c_0;
        rdata_c_1_stage2<=rdata_c_1;
        rdata_c_2_stage2<=rdata_c_2;
        rdata_c_3_stage2<=rdata_c_3;
        ccist_encode_stage2<=ccist_encode_i;//aamul:4 triadd:2 oacc:2
        ccvec_wdest_stage2<=ccvec_wdata_i;    
        ccvec_wmask_stage2<=ccvec_wmask_i;  
    end
end

assign add2_1_up = cus_add2_1_up_stage2?a1_o0_stage2:(~a1_o0_stage2+32'd1);
assign add2_2_up = cus_add2_2_up_stage2?a1_o1_stage2:(~a1_o1_stage2+32'd1);
assign add2_3_up = cus_add2_3_up_stage2?a1_o2_stage2:(~a1_o2_stage2+32'd1);
assign add2_4_up = cus_add1_4_up_stage2?a1_o3_stage2:(~a1_o3_stage2+32'd1);

assign add2_1_down = cus_add2_1_down_stage2[1]?rdata_c_0_stage2:cus_add2_1_down_stage2[0]?(~a1_o2_stage2+32'd1):a1_o1_stage2;
assign add2_2_down = cus_add2_2_down_stage2?rdata_c_1_stage2:a1_o2_stage2;
assign add2_3_down = cus_add2_3_down_stage2[1]?rdata_c_2_stage2:cus_add2_3_down_stage2[0]?(~a1_o1_stage2+32'd1):a1_o3_stage2;
assign add2_4_down = cus_add2_4_down_stage2?rdata_c_3_stage2:a1_o1_stage2;

assign a2_o0    =   add2_1_up   +   add2_1_down;
assign a2_o1    =   add2_2_up   +   add2_2_down;
assign a2_o2    =   add2_3_up   +   add2_3_down;
assign a2_o3    =   add2_4_up   +   add2_4_down;
assign stage2_wdata = {a2_o3,a2_o2,a2_o1,a2_o0};

//stage3 and stage4
always @(posedge clk) begin
    if(!rst_n) begin
        a2_o0_stage3 <= 0;
        a2_o1_stage3 <= 0;
        a2_o2_stage3 <= 0;
        a2_o3_stage3 <= 0;
        rdata_c_0_stage3 <= 0;
        rdata_c_1_stage3 <= 0;
        rdata_c_2_stage3 <= 0;
        rdata_c_3_stage3 <= 0;
        ccvec_wdest_stage3  <= 0;    
        ccvec_wmask_stage3  <= 0;
        ccvec_wdest_stage4  <= 0;    
        ccvec_wmask_stage4  <= 0;  
    end
    else begin
        if(stage23_fire) begin
            a2_o0_stage3 <= a2_o0;
            a2_o1_stage3 <= a2_o1;
            a2_o2_stage3 <= a2_o2;
            a2_o3_stage3 <= a2_o3;
            rdata_c_0_stage3 <= rdata_c_0_stage2;
            rdata_c_1_stage3 <= rdata_c_1_stage2;
            rdata_c_2_stage3 <= rdata_c_2_stage2;
            rdata_c_3_stage3 <= rdata_c_3_stage2;
            ccvec_wdest_stage3  <= ccvec_wdest_stage2;    
            ccvec_wmask_stage3  <= ccvec_wmask_stage2;
        end
        if(stage34_fire) begin
            ccvec_wdest_stage4  <= ccvec_wdest_stage3;    
            ccvec_wmask_stage4  <= ccvec_wmask_stage3;
        end 
    end
end

//stage4 hold on
//stage4-valid && !o_rdy -> use reg to hold cause mul can't block
    //ST3->ST4  ST3->ST3--ST4
always @(posedge clk) begin
    if(!rst_n) begin
        res_tmp_reg<=0;
        wdest_tmp_reg<=0;    
        wmask_tmp_reg<=0; 
        tmp_hold_on<0;
    end
    else if (valid_stage4 && !ccpu_ready_i && !tmp_hold_on)begin
        res_tmp_reg<=stage4_cal_data;
        wdest_tmp_reg<=ccvec_wdest_stage4;
        wmask_tmp_reg<=ccvec_wmask_stage4;
        tmp_hold_on<=1;
    end
    else if (valid_stage4 && ccpu_ready_i && tmp_hold_on)begin
        tmp_hold_on<=0;
    end
end

mult_gen_0 u_mult_gen_0 (
  .CLK(clk),  // input wire CLK
  .CE(1'b1),   // omit 
  .SCLR(1'b1), // omit 
  .A(a2_o0_stage3),      // input wire [31 : 0] A
  .B(rdata_c_0_stage3),  // input wire [31 : 0] B
  .P(m_o0)      // output wire [63 : 0] P
);

mult_gen_0 u_mult_gen_1 (
  .CLK(clk),  // input wire CLK
  .CE(1'b1),   // omit 
  .SCLR(1'b1), // omit 
  .A(a2_o1_stage3),      // input wire [31 : 0] A
  .B(rdata_c_1_stage3),  // input wire [31 : 0] B
  .P(m_o1)      // output wire [63 : 0] P
);

mult_gen_0 u_mult_gen_2 (
  .CLK(clk),  // input wire CLK
  .CE(1'b1),   // omit 
  .SCLR(1'b1), // omit 
  .A(a2_o2_stage3),      // input wire [31 : 0] A
  .B(rdata_c_2_stage3),  // input wire [31 : 0] B
  .P(m_o2)      // output wire [63 : 0] P
);

mult_gen_0 u_mult_gen_3 (
  .CLK(clk),  // input wire CLK
  .CE(1'b1),   // omit 
  .SCLR(1'b1), // omit 
  .A(a2_o3_stage3),      // input wire [31 : 0] A
  .B(rdata_c_3_stage3),  // input wire [31 : 0] B
  .P(m_o3)      // output wire [63 : 0] P
);

//AB:[0...0...16bit]
assign stage4_cal_data = {m_o3[31:0],m_o2[31:0],m_o1[31:0],m_o0[31:0]};
assign stage4_wdata_o = tmp_hold_on ? res_tmp_reg   : stage4_cal_data       ;
assign stage4_wdest_o = tmp_hold_on ? wdest_tmp_reg : ccvec_wdest_stage4    ;
assign stage4_wmask_o = tmp_hold_on ? wmask_tmp_reg : ccvec_wmask_stage4    ;

//out Signal
assign ccpu_ready_o     =   stage1_ready;
assign ccpu_valid_o     =   stage2_valid_o || valid_stage4;
assign ccvec_wdata_o    =   valid_stage4 ? stage4_wdata_o : stage2_wdata ;
assign ccvec_wmask_o    =   valid_stage4 ? stage4_wmask_o : ccvec_wmask_stage2 ;
assign ccvec_wdest_o    =   valid_stage4 ? stage4_wdest_o : ccvec_wdest_stage2 ;