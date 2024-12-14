module uart_rx(
    input rx,
    input s_tick,
    input reset,
    input [4:0] oversampling,
    output reg [7:0] dout,
    output reg rx_done
);
    localparam [1:0] 
        IDLE = 2'd0,
        DATA = 2'd1, 
        STOP = 2'd2;

    localparam [3:0] DATA_SIZE = 4'd8;

    reg [1:0] state;
    reg [4:0] counter;
    reg [3:0] bit_position;

    // Registers to enable majority decision
    reg [3:0] zero_count;
    reg [3:0] one_count;

    task reset_rx(input rx_done_bit, input dout_reset);
        begin
            if (dout_reset)
                dout <= 0;

            rx_done <= rx_done_bit;
            state <= IDLE;
            counter <= 0;
            bit_position <= 0;
            one_count <= 0;
            zero_count <= 0;
        end
    endtask

    always @(posedge s_tick) begin
        if (reset) begin
            reset_rx(0, 1);
        end else begin
            case (state)
                IDLE:
                    // Sampling in the middle of the start bit, @8 allows for middling sampling @15 for the data bits
                    if (rx == 0 && (counter == (oversampling / 2))) begin
                        rx_done <= 0;
                        dout <= 0;
                        state <= DATA;
                        counter <= 0; // Starts counting from relative 0, which is now the middle of each bit
                        bit_position <= 0;
                    end else begin
                        counter <= (counter + 1) % oversampling;
                    end
                DATA: begin
                    if (counter == oversampling - 1) begin
                        if (bit_position == DATA_SIZE - 1)
                            state <= STOP;
                        
                        dout <= {dout[6:0], (one_count > zero_count) ? 1'b1 : 1'b0};

                        // dout <= {dout[6:0], rx};
                        bit_position <= bit_position + 1;

                        // Reset counters for next bit
                        zero_count <= 0;
                        one_count <= 0;
                    end else begin
                        // Track oversampled 1 and 0 counts
                        if (rx)
                            one_count <= one_count + 1;
                        else
                            zero_count <= zero_count + 1;
                    end

                    counter <= (counter + 1) % oversampling;
                end
                STOP:
                    if (counter == 0) begin
                        reset_rx(1, 0);
                    end else
                        counter <= (counter + 1) % oversampling;
            endcase
        end
    end

endmodule