// 1. BAUD GENERATOR
// Function: Creates a timing reference (tick) for the UART system.
// ====================================================================
module baud_gen #(parameter THRESHOLD = 10) (
    input  clk,          // System clock (100MHz in this simulation)
    input  reset,        // Resets the counter to 0 to sync with the RX
    output reg tick      // Pulses '1' every THRESHOLD cycles (the 16x oversampling clock)
);
    reg [15:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            tick    <= 0; 
        end else if (counter == THRESHOLD - 1) begin
            tick    <= 1; 
            counter <= 0;
        end else begin
            tick    <= 0; 
            counter <= counter + 1;
        end
    end
endmodule

// ====================================================================
// 2. UART TRANSMITTER (TX)
// Function: Converts 8-bit parallel data into a serial stream.
// ====================================================================
module uart_tx (
    input  clk,         
    input  reset,       
    input  tick,         // The baud tick from the generator
    input  start,        // Signal from testbench to begin transmission
    input  [7:0] data,   // The 8-bit byte to be sent 
    output reg tx_pin,   // The physical serial wire carrying the bits
    output reg active    // High when the transmitter is busy sending
);
    localparam IDLE  = 2'b00, 
               START = 2'b01, 
               DATA  = 2'b10, 
               STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] s_count;   // Counts 16 ticks to create one full bit width
    reg [2:0] b_count;   // Counts which of the 8 bits we are sending
    reg [7:0] b_reg;     // Internal buffer to hold data during transmission

    always @(posedge clk) begin
        if (reset) begin
            state   <= IDLE; 
            tx_pin  <= 1'b1; // UART idle state is logic HIGH
            active  <= 0; 
            s_count <= 0; 
            b_count <= 0; 
            b_reg   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_pin <= 1; 
                    active <= 0;
                    if (start) begin 
                        b_reg   <= data; 
                        state   <= START; 
                        s_count <= 0; 
                    end
                end

                START: begin
                    active <= 1; 
                    tx_pin <= 0; // Sends the Start Bit (Logic 0)
                    if (tick) begin
                        if (s_count == 15) begin 
                            state   <= DATA; 
                            s_count <= 0; 
                            b_count <= 0; 
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end

                DATA: begin
                    tx_pin <= b_reg[b_count]; // Serializes the data bit by bit
                    if (tick) begin
                        if (s_count == 15) begin
                            s_count <= 0;
                            if (b_count == 7) begin
                                state <= STOP;
                            end else begin
                                b_count <= b_count + 1;
                            end
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end

                STOP: begin
                    tx_pin <= 1; // Sends the Stop Bit (Logic 1)
                    if (tick) begin
                        if (s_count == 15) begin
                            state <= IDLE;
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule

// ====================================================================
// 3. UART RECEIVER (RX)
// Function: Uses 16x oversampling to capture serial data accurately.
// ====================================================================
module uart_rx (
    input  clk,          // System clock
    input  reset,        // Resets FSM to IDLE state
    input  s_tick,       // 16x oversampling clock pulse
    input  rx_pin,       // Listens to the serial wire (connected to tx_wire)
    output reg [7:0] data,  // The assembled 8-bit byte
    output reg rx_done   // Pulses high for 1 cycle when data is ready
);
    localparam IDLE  = 2'b00, 
               START = 2'b01, 
               DATA  = 2'b10, 
               STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] s_count;   // Oversampling counter (0-15)
    reg [2:0] b_count;   // Counts bits received (0-7)
    reg [7:0] b_reg;     // Shift register to assemble the bits

    always @(posedge clk) begin
        if (reset) begin
            state   <= IDLE; 
            rx_done <= 0; 
            data    <= 0;
            s_count <= 0; 
            b_count <= 0; 
            b_reg   <= 0;
        end else begin
            rx_done <= 0;
            case (state)
                IDLE: begin
                    if (rx_pin == 0) begin // Detect the falling edge of the Start Bit
                        state   <= START; 
                        s_count <= 0; 
                    end
                end

                START: begin
                    if (s_tick) begin
                        // Wait 8 ticks to reach the CENTER of the start bit
                        if (s_count == 7) begin 
                            state   <= DATA; 
                            s_count <= 0; 
                            b_count <= 0; 
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end

                DATA: begin
                    if (s_tick) begin
                        // Samples at the 16th tick (center of the data bit)
                        if (s_count == 15) begin
                            s_count <= 0;
                            b_reg   <= {rx_pin, b_reg[7:1]}; // LSB first shift
                            if (b_count == 7) begin
                                state <= STOP;
                            end else begin
                                b_count <= b_count + 1;
                            end
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end

                STOP: begin
                    if (s_tick) begin
                        if (s_count == 15) begin 
                            data    <= b_reg;   // Byte assembly complete
                            rx_done <= 1;       // Trigger data-ready pulse
                            state   <= IDLE; 
                        end else begin
                            s_count <= s_count + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule

// ====================================================================
// 4. TOP MODULE 
// Function: Ties the TX and RX together for verification.
// ====================================================================
module uart_top (
    input  clk, 
    input  reset, 
    input  start,
    input  [7:0] tx_data,
    output [7:0] rx_data,
    output rx_done, 
    output tx_wire
);
    wire baud_tick;

    
    baud_gen #(.THRESHOLD(10)) b_gen (
        .clk(clk), 
        .reset(reset), 
        .tick(baud_tick)
    );
    
    // TX outputs to tx_wire
    uart_tx tx_u (
        .clk(clk), 
        .reset(reset), 
        .tick(baud_tick), 
        .start(start), 
        .data(tx_data), 
        .tx_pin(tx_wire)
    );
    
    // RX listens to tx_wire 
    uart_rx rx_u (
        .clk(clk), 
        .reset(reset), 
        .s_tick(baud_tick), 
        .rx_pin(tx_wire), 
        .data(rx_data), 
        .rx_done(rx_done)
    );
endmodule
