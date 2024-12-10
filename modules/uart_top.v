module uart_top(
    input [7:0] tx_data, input s_tick, input tx_reset, input tx_transmission, output tx, output tx_done,
    input rx, input rx_reset, output [7:0] dout, output rx_done
);
    uart_tx tx_mod(.data(tx_data), .s_tick(s_tick), .reset(tx_reset), .transmission(tx_transmission), .tx(tx), .tx_done(tx_done));
    uart_rx rx_mod(.rx(rx), .s_tick(s_tick), .reset(rx_reset), .dout(dout), .rx_done(rx_done));

endmodule