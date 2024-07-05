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
    output logic [127:0] rdata3
);

reg [127:0] vector_register[10:0];
always @(posedge clk) begin
    if(!rst_n) begin
        vector_register <=0 ;
    end
    else if(we) begin
        vector_register[waddr] <= wdata & {{32{wmask[3]}},{32{wmask[2]}},{32{wmask[1]}},{32{wmask[0]}}};
    end
end

assign rdata1 = vector_register[raddr1];
assign rdata2 = vector_register[raddr2];
assign rdata3 = vector_register[raddr3];

endmodule