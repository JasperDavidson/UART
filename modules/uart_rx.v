module uart_rx(
    input rx,
    input s_tick,
    input reset,
    output reg [7:0] dout,
    output reg rx_done
);
    localparam [1:0] 
        IDLE = 2'd0,
        DATA = 2'd1, 
        STOP = 2'd2;

    localparam [3:0] DATA_SIZE = 4'd8;
    localparam [1:0] OVERSAMPLING_AMOUNT = 2'd1;

    reg [1:0] state;
    reg [4:0] counter;
    reg [3:0] bit_position;

    task reset_rx(input rx_done_bit, input dout_reset);
        begin
            if (dout_reset)
                dout <= 0;

            rx_done <= rx_done_bit;
            state <= IDLE;
            counter <= 0;
            bit_position <= 0;
        end
    endtask

    always @(posedge s_tick) begin
        if (reset) begin
            reset_rx(0, 1);
        end else begin
            case (state)
                IDLE:
                    // Sampling in the middle of the start bit, @7 allows for middling sampling @15 for the data bits
                    if (rx == 0) begin
                        $display("Start receiving");
                        rx_done <= 0;
                        dout <= 0;
                        state <= DATA;
                        counter <= 0;
                        bit_position <= 0;
                    end else begin
                        counter <= (counter + 1) - ((counter + 1) / OVERSAMPLING_AMOUNT) * OVERSAMPLING_AMOUNT;
                    end
                DATA:
                    if (counter == 0) begin
                        if (bit_position == DATA_SIZE - 1)
                            state <= STOP;

                        dout <= {dout[6:0], rx};
                        bit_position <= bit_position + 1;
                        counter <= 0;
                    end else
                        counter <= counter + 0;
                STOP:
                    if (counter == 0) begin
                        reset_rx(1, 0);
                    end else
                        counter <= counter + 0;
            endcase
        end
    end

endmodule