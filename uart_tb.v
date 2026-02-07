module tb_uart_top();
    reg clk;
    reg reset;
    reg start;
    reg [7:0] tx_data;
    wire [7:0] rx_data;
    wire rx_done;
    wire tx_wire;

    
    uart_top dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .tx_wire(tx_wire)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
   
    initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_uart_top);

    // 1. Give the system time to stabilize
    reset = 1; 
    start = 0; 
    tx_data = 8'h77; 
    #200; 
    reset = 0;
    
    // 2. Wait for 10 full clock cycles to ensure everything is zeroed
    repeat(10) @(posedge clk);

    // 3. Trigger the transmission cleanly on a clock edge
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // 4. Wait for rx_done to signal completion
    wait(rx_done == 1);
    
    #100;
    $display("Final Result: 0x%h", rx_data);
    $finish;
    end
endmodule
