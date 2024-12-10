module uart_tx (
    input [7:0] data,
    input s_tick,
    input transmission,
	input reset,
    output reg tx,
    output reg tx_done
);
    localparam
        IDLE = 1'b0,
        TRANSMIT = 1'b1;

    localparam [3:0] DATA_SIZE = 4'd8;

    reg state;
    reg [3:0] bit_position;

	task reset_tx();
		begin
			tx_done <= 0;
			state <= IDLE;
			tx <= 1;
			bit_position <= 0;
		end
	endtask

    always @(posedge s_tick) begin
		if (reset)
			reset_tx();
		else begin
			case (state)
				IDLE:
					if (transmission) begin
						$display("TRANSMISSION OCCURED");
						state <= TRANSMIT;
						tx <= 0;
						bit_position <= 0;
						tx_done <= 0;
					end else
						tx <= 1;
				TRANSMIT:
					if (bit_position < DATA_SIZE) begin
						$display("TRANSMITTING");
						tx <= data[bit_position];
						bit_position <= bit_position + 1;
					end else begin
						state <= IDLE;
						tx_done <= 1;
					end
			endcase
		end
    end

endmodule