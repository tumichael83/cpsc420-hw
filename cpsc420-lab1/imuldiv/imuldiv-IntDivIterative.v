//========================================================================
// Lab 1 - Iterative Div Unit
//========================================================================

`ifndef PARC_INT_DIV_ITERATIVE_V
`define PARC_INT_DIV_ITERATIVE_V

`include "imuldiv-DivReqMsg.v"
`include "vc-Muxes.v"
`include "vc-StateElements.v"

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

  wire         cntr_mux_sel;
  wire         sign_en;
  wire         is_op_signed;
  wire         a_mux_sel;
  wire         a_en;
  wire         b_en;
  wire         sub_mux_sel;
  wire         rem_sign_mux_sel;
  wire         div_sign_mux_sel;
  wire   [4:0] counter;
  wire         div_sign;
  wire         rem_sign;
  wire         diff_sign;

  imuldiv_IntDivIterativeDpath dpath
  (
    .clk                  (clk),
    .divreq_msg_a         (divreq_msg_a),
    .divreq_msg_b         (divreq_msg_b),
    .cntr_mux_sel_in      (cntr_mux_sel),
    .sign_en_in           (sign_en),
    .is_op_signed_in      (is_op_signed),
    .a_mux_sel_in         (a_mux_sel),
    .a_en_in              (a_en),
    .b_en_in              (b_en),
    .sub_mux_sel_in       (sub_mux_sel),
    .rem_sign_mux_sel_in  (rem_sign_mux_sel),
    .div_sign_mux_sel_in  (div_sign_mux_sel),
    .counter_out          (counter),
    .div_sign_out         (div_sign),
    .rem_sign_out         (rem_sign),
    .diff_sign_out        (diff_sign),
    .divresp_msg_result   (divresp_msg_result)
  );

  imuldiv_IntDivIterativeCtrl ctrl
  (
    .clk                  (clk),
    .reset                (reset),

    .divreq_msg_fn        (divreq_msg_fn),
    .divreq_val           (divreq_val),
    .divresp_rdy          (divresp_rdy),
    .divresp_val          (divresp_val),
    .divreq_rdy           (divreq_rdy),

    .counter_in           (counter),
    .div_sign_in          (div_sign),
    .rem_sign_in          (rem_sign),
    .diff_sign_in         (diff_sign),

    .cntr_mux_sel_out     (cntr_mux_sel),
    .sign_en_out          (sign_en),
    .is_op_signed_out     (is_op_signed),
    .a_mux_sel_out        (a_mux_sel),
    .a_en_out             (a_en),
    .b_en_out             (b_en),
    .sub_mux_sel_out      (sub_mux_sel),
    .rem_sign_mux_sel_out (rem_sign_mux_sel),
    .div_sign_mux_sel_out (div_sign_mux_sel)
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

  // Control Inputs (ctrl->dpath)
  input         cntr_mux_sel_in,
  input         sign_en_in,
  input         is_op_signed_in,
  input         a_mux_sel_in,
  input         a_en_in,
  input         b_en_in,
  input         sub_mux_sel_in,
  input         rem_sign_mux_sel_in,
  input         div_sign_mux_sel_in,

  // Control Outputs (dpath->ctrl)
  output reg   [4:0] counter_out,
  output             div_sign_out,
  output             rem_sign_out,
  output             diff_sign_out,

  // Data Outputs
  output [63:0] divresp_msg_result // Result of operation
);
  //------------------------------------------------------------
  // Counter
  //------------------------------------------------------------

  always @ ( posedge clk ) begin
    if (cntr_mux_sel_in)
      counter_out <= 5'd31;
    else
      counter_out <= counter_out - 1;
  end

  //------------------------------------------------------------
  // Sign Registers
  //------------------------------------------------------------

  vc_EDFF_pf#(1)  div_sign_reg
  (
    .clk        (clk),
    .d_p        (divreq_msg_a[31] ^ divreq_msg_b[31]),
    .en_p       (sign_en_in),
    .q_np       (div_sign_out)
  );

  vc_EDFF_pf#(1)  rem_sign_reg
  (
    .clk        (clk),
    .d_p        (divreq_msg_a[31]),
    .en_p       (sign_en_in),
    .q_np       (rem_sign_out)
  );

  //------------------------------------------------------------
  // a path to reg
  //------------------------------------------------------------

  wire    [64:0]  sub_mux_out;

  wire    [31:0]  unsigned_a;
  opUnsign#(32) a_unsign
  (
    .in           (divreq_msg_a),
    .is_op_signed (is_op_signed_in),
    .out          (unsigned_a)
  );

  wire    [64:0]  a_mux_out;
  vc_Mux2#(65)  a_mux
  (
    .in0      (sub_mux_out),
    .in1      ({33'b0, unsigned_a}),
    .sel      (a_mux_sel_in),
    .out      (a_mux_out)
  );

  wire    [64:0]  a_reg_out;
  vc_EDFF_pf#(65) a_reg
  (
    .clk        (clk),
    .d_p        (a_mux_out),
    .en_p       (a_en_in),
    .q_np       (a_reg_out)
  );

  //------------------------------------------------------------
  // b path to reg
  //------------------------------------------------------------

  wire    [31:0]  unsigned_b;
  opUnsign#(32) b_unsign
  (
    .in           (divreq_msg_b),
    .is_op_signed (is_op_signed_in),
    .out          (unsigned_b)
  );
  
  wire    [64:0]  b_reg_out;
  vc_EDFF_pf#(65) b_reg
  (
    .clk        (clk),
    .d_p        ({1'b0, unsigned_b, 32'b0}),
    .en_p       (b_en_in),
    .q_np       (b_reg_out)
  );

  //------------------------------------------------------------
  // calculation logic
  //------------------------------------------------------------

  wire  [64:0]  a_shift_out = a_reg_out << 1;

  wire  [64:0]  sub_out = a_shift_out - b_reg_out;

  assign diff_sign_out = sub_out[64];

  vc_Mux2#(65) sub_mux
  (
    .in0      (a_shift_out),
    .in1      ({sub_out[64:1], 1'b1}),
    .sel      (sub_mux_sel_in),
    .out      (sub_mux_out)
  );


  //------------------------------------------------------------
  // Output logic
  //------------------------------------------------------------

  wire  [31:0]  signed_res_rem_mux_out;
  vc_Mux2#(32) rem_sign_mux
  (
    .in0      (~a_reg_out[63:32]+1'b1),
    .in1      (a_reg_out[63:32]),
    .sel      (rem_sign_mux_sel_in),
    .out      (signed_res_rem_mux_out)
  );

  wire  [31:0]  signed_res_div_mux_out;
  vc_Mux2#(32) div_sign_mux
  (
    .in0      (~a_reg_out[31:0]+1'b1),
    .in1      (a_reg_out[31:0]),
    .sel      (div_sign_mux_sel_in),
    .out      (signed_res_div_mux_out)
  );

  assign  divresp_msg_result = {signed_res_rem_mux_out, signed_res_div_mux_out};

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeCtrl
(
  input           clk,
  input           reset,

  // Data inputs / outputs
  input           divreq_msg_fn,

  input           divreq_val,
  input           divresp_rdy,

  output  reg     divresp_val,
  output  reg     divreq_rdy,

  // Control inputs  (dpath -> ctrl)
  input     [4:0] counter_in,
  input           div_sign_in,
  input           rem_sign_in,
  input           diff_sign_in,

  // Control Outputs (ctrl -> dpth)
  output  reg     cntr_mux_sel_out, //
  output  reg     sign_en_out,      //
  output          is_op_signed_out,  //
  output  reg     a_mux_sel_out,
  output  reg     a_en_out,  
  output  reg     b_en_out, 
  output  reg     sub_mux_sel_out,
  output  reg     rem_sign_mux_sel_out,
  output  reg     div_sign_mux_sel_out
);

  localparam  WAIT = 0;
  localparam  CALC = 1;
  localparam  DONE = 2;

  reg       [1:0] state;
  reg       [1:0] next_state;

  //---------------------
  // State transition
  //---------------------

  always @ (posedge clk) begin
    if ( reset )
      state <= WAIT;
    else 
      state <= next_state;
  end

  //---------------------
  // Next State Logic (combinational, note, non-blocking assgn)
  //---------------------

  always @( * ) begin
    next_state = state;
    case ( state ) 
      WAIT : begin
        if ( divreq_val )
          next_state = CALC;
      end

      CALC : begin
        if (counter_in == 0)
          next_state = DONE;
      end

      DONE : begin
        if (divresp_rdy)
          next_state = WAIT;
      end
    endcase
  end

  //---------------------
  // output logic
  //---------------------

  // think about this one some more
  assign is_op_signed_out = divreq_msg_fn;

  always @ ( * ) begin
    case ( state )
      WAIT : begin
        divreq_rdy = 1'b1;
        cntr_mux_sel_out = 1'b1;
        sign_en_out = 1'b1;
        a_mux_sel_out = 1'b1;
        a_en_out = 1'b1;
        b_en_out = 1'b1;
        divresp_val = 1'b0;
      end

      CALC : begin
        divreq_rdy = 1'b0;
        cntr_mux_sel_out = 1'b0;
        sign_en_out = 1'b0;
        a_mux_sel_out = 1'b0;
        a_en_out = 1'b1;
        b_en_out = 1'b0;

        // based on signs
        if (diff_sign_in)
          sub_mux_sel_out = 1'b0;
        else
          sub_mux_sel_out = 1'b1;

        if (rem_sign_in)
          rem_sign_mux_sel_out = 1'b0;
        else
          rem_sign_mux_sel_out = 1'b1;

        if (div_sign_in)
          div_sign_mux_sel_out = 1'b0;
        else
          div_sign_mux_sel_out = 1'b1;

        divresp_val = 1'b0;
      end

      DONE : begin
        divreq_rdy = 1'b0;
        cntr_mux_sel_out = 1'b1;
        sign_en_out = 1'b0;
        a_en_out = 1'b0;
        b_en_out = 1'b0;

        // output mux should hold constant
        if (rem_sign_in)
          rem_sign_mux_sel_out = 1'b0;
        else
          rem_sign_mux_sel_out = 1'b1;

        if (div_sign_in)
          div_sign_mux_sel_out = 1'b0;
        else
          div_sign_mux_sel_out = 1'b1;

        divresp_val = 1'b1;
      end

    endcase
  end

endmodule

module opUnsign #( parameter W = 32 )
  (
    input      [W-1:0] in,
    input              is_op_signed,
    output     [W-1:0] out
  );

    assign out
    = (is_op_signed) 
      ? ((in[W-1]) 
        ? (~in + 1'b1) 
        : (in))
      : in;

endmodule

`endif
