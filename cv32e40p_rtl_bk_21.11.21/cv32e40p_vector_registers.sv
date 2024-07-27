module cv32e40p_vector_registers(
    input logic         clk,
    input logic         rst_n,
    
    //write port
    input logic we,
    input logic [3:0]   waddr,
    input logic [127:0] wdata,
    input logic [3:0]   wmask,

    //read port
    input logic [3:0]   raddr1,
    input logic [3:0]   raddr2,
    input logic [3:0]   raddr3,
    output logic [127:0] rdata1,
    output logic [127:0] rdata2,
    output logic [127:0] rdata3,

    //issue judge
    input logic ccpu_wenist_fire,//fire && wen
    input logic [3:0] ccpu_iss_dest,
    input logic [2:0] ccpu_need_rdata,
    output logic ccpu_data_rdy
);

reg [127:0] vector_register[10:0];
reg write_recoder[10:0];

always @(posedge clk) begin
    if(!rst_n) begin
        vector_register <=0 ;
    end
    else if(we) begin
        vector_register[waddr] <= wdata & {{32{wmask[3]}},{32{wmask[2]}},{32{wmask[1]}},{32{wmask[0]}}};
    end
end

always @(posedge clk) begin
    if(!rst_n) begin
        write_recoder   <=0 ;
    end
    else begin
        if(we && ccpu_wenist_fire) begin
            if(ccpu_iss_dest==waddr)begin
                write_recoder[ccpu_iss_dest]<=1;
            end
            else begin
                write_recoder[waddr] <= 0;
                write_recoder[ccpu_iss_dest]<=1;
            end
        end   
        else if (we) begin
            write_recoder[waddr] <= 0;
        end
        else if (ccpu_wenist_fire) begin
            write_recoder[ccpu_iss_dest]<=1;
        end   
    end
end

assign rdata1 = vector_register[raddr1];
assign rdata2 = vector_register[raddr2];
assign rdata3 = vector_register[raddr3];

assign ccpu_data_rdy = !(write_recoder[raddr1] & ccpu_need_rdata[0]
|| write_recoder[raddr2] & ccpu_need_rdata[1] 
|| write_recoder[raddr3] & ccpu_need_rdata[2]);

endmodule