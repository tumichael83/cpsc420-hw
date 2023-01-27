//========================================================================
// Lab 1 - Iterative Div Unit
//========================================================================

`ifndef PARC_INT_DIV_ITERATIVE_V
`define PARC_INT_DIV_ITERATIVE_V

`include "imuldiv-DivReqMsg.v"

module imuldiv_IntDivIterative
(

  input         clk,
  input         reset,

  input         divreq_msg_fn,
  input  [31:0] divreq_msg_a,
  input  [31:0] divreq_msg_b,
  input         divreq_val,
  output        divreq_rdy,

  output [63:0] divresp_msg_result,
  output        divresp_val,
  input         divresp_rdy
);

  imuldiv_IntDivIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),
    .divreq_msg_fn      (divreq_msg_fn),
    .divreq_msg_a       (divreq_msg_a),
    .divreq_msg_b       (divreq_msg_b),
    .divreq_val         (divreq_val),
    .divreq_rdy         (divreq_rdy),
    .divresp_msg_result (divresp_msg_result),
    .divresp_val        (divresp_val),
    .divresp_rdy        (divresp_rdy)
  );

  imuldiv_IntDivIterativeCtrl ctrl
  (
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeDpath
(
  input         clk,

  // Data Inputs
  input  [31:0] divreq_msg_a,       // Operand A
  input  [31:0] divreq_msg_b,       // Operand B

  // Control Inputs
  input         cntr_mux_sel_in,
  input         sign_en_in,

  // Control Outputs
  output  reg   [4:0] counter,
  output  reg   div_sign_out;
  output  reg   rem_sign;

  // Data Outputs
  output [63:0] divresp_msg_result // Result of operation
);
  //------------------------------------------------------------
  // Counter
  //------------------------------------------------------------

  always @ ( posedge clk ) begin
    if (cntr_mux_sel_in)
      counter <= 5'd31;
    else
      counter <= counter - 1;
  end

  //------------------------------------------------------------
  // Sign Registers
  //------------------------------------------------------------

  always @ ( posedge clk ) begin
    if ( sign_en_in ) begin
        div_sign_reg <= divreq_msg_a[31] ^ divreq_msg_b[31];
        rem_sign_reg <= divreq_msg_a[31];
    end
  end

  //------------------------------------------------------------
  // Sign Registers
  //------------------------------------------------------------

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeCtrl
(
  input           clk,
  input           reset,

  input           divreq_msg_fn,

  input           divreq_val,
  input           divrsp_rdy,

  output          divrsp_val,
  output          divreq_rdy
);

  always @ (posedge clk) begin
    if ( divresp_rdy ) begin

    end
  end

endmodule

`endif
