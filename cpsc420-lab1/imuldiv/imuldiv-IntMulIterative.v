//========================================================================
// Lab 1 - Iterative Mul Unit
//========================================================================

`ifndef PARC_INT_MUL_ITERATIVE_V
`define PARC_INT_MUL_ITERATIVE_V

`include "vc-Arith.v"
`include "vc-Muxes.v"
`include "vc-StateElements.v"

module imuldiv_IntMulIterative
(
  input          clk,
  input          reset,

  input  [31:0]  mulreq_msg_a,
  input  [31:0]  mulreq_msg_b,
  input          mulreq_val,
  output         mulreq_rdy,

  output [63:0]  mulresp_msg_result,
  output         mulresp_val,
  input          mulresp_rdy
);

  wire          cntr_mux_sel;
  wire          a_mux_sel;
  wire          b_mux_sel;
  wire          result_en;
  wire          result_mux_sel;
  wire          result_mux_en;
  wire          add_mux_sel;
  wire          sign_mux_sel;
  wire          sign_en;
  wire          add_to_result;
  wire    [4:0] counter;
  wire          sign;

  imuldiv_IntMulIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),

    .mulreq_msg_a       (mulreq_msg_a),
    .mulreq_msg_b       (mulreq_msg_b),
    .mulresp_msg_result (mulresp_msg_result),

    .cntr_mux_sel_in    (cntr_mux_sel),

    .a_mux_sel_in       (a_mux_sel),
    .b_mux_sel_in       (b_mux_sel),

    .result_mux_sel_in  (result_mux_sel),
    .result_en_in       (result_en),
    .add_mux_sel_in     (add_mux_sel),

    .sign_mux_sel_in    (sign_mux_sel),
    .sign_en_in         (sign_en),

    .add_to_result_out  (add_to_result),
    .counter_out        (counter),
    .sign_out           (sign)
  );

  imuldiv_IntMulIterativeCtrl ctrl
  (
    .clk                (clk),
    .reset              (reset),
    .mulreq_val         (mulreq_val),
    .mulreq_rdy         (mulreq_rdy),
    .mulresp_rdy        (mulresp_rdy),
    .mulresp_val        (mulresp_val),
    .add_to_result_in   (add_to_result),
    .counter_in         (counter),
    .sign_in            (sign),
    .cntr_mux_sel_out   (cntr_mux_sel),
    .a_mux_sel_out      (a_mux_sel),
    .b_mux_sel_out      (b_mux_sel),
    .result_mux_sel_out (result_mux_sel),
    .result_en_out      (result_en),
    .add_mux_sel_out    (add_mux_sel),
    .sign_mux_sel_out   (sign_mux_sel),
    .sign_en_out        (sign_en)
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntMulIterativeDpath
(
  input         clk,
  input         reset,
  
  // Data Signals
  input   [31:0] mulreq_msg_a,
  input   [31:0] mulreq_msg_b,
  output  [63:0] mulresp_msg_result,

  // Control Input Signals (ctrl->dpath)
  input          cntr_mux_sel_in,

  input          a_mux_sel_in,
  input          b_mux_sel_in,
  
  input          result_mux_sel_in,
  input          result_en_in,
  input          add_mux_sel_in,

  input          sign_mux_sel_in,
  input          sign_en_in,

  // Control Output Signals (dpath->Ctrl)
  output         add_to_result_out,

  output   [4:0] counter_out,

  output         sign_out
);

    //--------------------------------------
    // path for counter register
    //--------------------------------------
    wire    [4:0] counter_mux_out;
    wire    [4:0] counter_dec_out;
    assign counter_mux_out
      = ( cntr_mux_sel_in ) ? 5'd31 : counter_dec_out;

    vc_DFF_pf #(5) counter_reg
    (
      .clk          (clk),
      .d_p          (counter_mux_out),
      .q_np         (counter_out)
    );

    vc_Inc#(.W(5), .INC(-1)) count_dec
    (
      .in           (counter_out),
      .out          (counter_dec_out)
    );

    //--------------------------------------
    // sign_reg
    //--------------------------------------
    wire          calc_sign;
    assign calc_sign
      = mulreq_msg_a[31] ^ mulreq_msg_b[31];

    vc_EDFF_pf#(1) sign_reg
    (
      .clk            (clk),
      .d_p            (calc_sign),
      .en_p           (sign_en_in),
      .q_np           (sign_out)
    );

    //--------------------------------------
    // path for message a
    //--------------------------------------
    wire  [63:0]  extended_a;
    wire  [63:0]  a_mux_out;
    wire  [63:0]  a_reg_out;
    wire  [63:0]  a_shift_out;
    UnsignExtendA ext_a 
    (
      .in         (mulreq_msg_a),
      .out        (extended_a)
    );

    vc_Mux2#(64) a_mux 
    (
      .in0      (a_shift_out),
      .in1      (extended_a),
      .sel      (a_mux_sel_in),
      .out      (a_mux_out)
    );

    vc_DFF_pf#(64) a_reg
    (
      .clk      (clk),
      .d_p      (a_mux_out),
      .q_np     (a_reg_out)
    );

    assign a_shift_out 
      = a_reg_out << 1;

    //--------------------------------------
    // path for message b
    //--------------------------------------
    wire  [31:0]  unsigned_b;
    wire  [31:0]  b_mux_out;
    wire  [31:0]  b_reg_out;
    wire  [31:0]  b_shift_out;
    unsign#(32) unsign_b
    (
      .in         (mulreq_msg_b),
      .out        (unsigned_b)
    );

    vc_Mux2#(32) b_mux 
    (
      .in0      (b_shift_out),
      .in1      (unsigned_b),
      .sel      (b_mux_sel_in),
      .out      (b_mux_out)
    );

    vc_DFF_pf#(32) b_reg
    (
      .clk      (clk),
      .d_p      (b_mux_out),
      .q_np     (b_reg_out)
    );

    assign add_to_result_out
      = b_reg_out[0];

    assign b_shift_out 
      = b_reg_out >> 1;

    //--------------------------------------
    // path for result register
    //--------------------------------------
    wire  [63:0]  result_mux_out;
    wire  [63:0]  result_reg_out;
    wire  [63:0]  result_added_a;
    wire  [63:0]  add_mux_out;
    // use new module for this? --> constant 0 may be a problem
    assign result_mux_out 
      = (result_mux_sel_in) ? 64'b0 : add_mux_out;

    vc_EDFF_pf#(64) result_reg
    (
      .clk      (clk),
      .d_p      (result_mux_out),
      .en_p     (result_en_in),
      .q_np     (result_reg_out)
    );

    assign result_added_a
      = a_reg_out + result_reg_out;

    vc_Mux2#(64) add_mux 
    (
      .in0        (result_added_a),
      .in1        (result_reg_out),
      .sel        (add_mux_sel_in),
      .out        (add_mux_out)
    );

    //--------------------------------------
    // path for signing data
    //--------------------------------------
    wire    [63:0]  signed_result;
    sign#(64) result_signer 
    (
      .in         (result_reg_out),
      .out        (signed_result)
    );

    vc_Mux2#(64) sign_mux
    (
      .in0        (signed_result),
      .in1        (result_reg_out),
      .sel        (sign_mux_sel_in),
      .out        (mulresp_msg_result)
    );

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module imuldiv_IntMulIterativeCtrl
(
  input          clk,
  input          reset,

  // Data Signals (val / rdy) control flow
  input          mulreq_val,  // inputs valid?
  output  reg    mulreq_rdy,  // rdy for new input?

  input          mulresp_rdy, // receiver rdy?
  output  reg    mulresp_val, // calculated value is rdy

  // Control Input Signals (dpath->ctrl)
  input          add_to_result_in,

  input    [4:0] counter_in,
  
  input          sign_in,

  // Control output Signals (ctrl->dpath)
  output  reg    cntr_mux_sel_out,

  output  reg    a_mux_sel_out,
  output  reg    b_mux_sel_out,
  
  output  reg    result_mux_sel_out,
  output  reg    result_en_out,
  output  reg    add_mux_sel_out,

  output  reg    sign_mux_sel_out,
  output  reg    sign_en_out
);

  localparam WAIT = 0;
  localparam CALC = 1;
  localparam DONE = 2;
  
  reg  [1:0]     state;
  reg  [1:0]     state_next;

  //-----------------------------------------
  // state register (register transfer level)
  //-----------------------------------------
  always @ ( posedge clk )
    if ( reset )
      state <= WAIT;
    else
      state = state_next;

  //-------------------------------------------
  // next state logic (note it's combinational)
  //-------------------------------------------
  always @ (*)
  begin
    // default is stay in same state
    state_next = state;

    case ( state )
      WAIT : 
        if ( mulreq_val )
          state_next = CALC;

      CALC :
        if ( counter_in == 0 )
          state_next = DONE;

      DONE : 
        if ( mulresp_rdy )
          state_next = WAIT;
    endcase
  end

  //-------------------------------------------
  // output logic (note it's combinational)
  //-------------------------------------------

  always @ (*)
  begin
    case (state)
      WAIT : begin
        mulreq_rdy = 1'b1;
        cntr_mux_sel_out = 1'b1;
        a_mux_sel_out = 1'b1;
        b_mux_sel_out = 1'b1;
        result_mux_sel_out = 1'b1;
        result_en_out = 1'b1;
        add_mux_sel_out = 1'b1;
        sign_mux_sel_out = 1'b0;
        sign_en_out = 1'b1;
        mulresp_val = 1'b0;
        end
      
      CALC : begin
        mulreq_rdy = 1'b0;
        cntr_mux_sel_out = 1'b0;
        a_mux_sel_out = 1'b0;
        b_mux_sel_out = 1'b0;
        result_mux_sel_out = 1'b0;
        result_en_out = 1'b1;

        if ( add_to_result_in )
          add_mux_sel_out = 1'b0;
        else
          add_mux_sel_out = 1'b1;

        sign_en_out = 1'b0;
        mulresp_val = 1'b0;
        end

      DONE : begin
        mulreq_rdy = 1'b0;
        cntr_mux_sel_out = 1'b1;
        a_mux_sel_out = 1'b1;
        b_mux_sel_out = 1'b1;
        result_mux_sel_out = 1'b1;
        result_en_out = 1'b0;
        add_mux_sel_out = 1'b0;

        if ( sign_in )
          sign_mux_sel_out = 1'b0;
        else
          sign_mux_sel_out = 1'b1;

        sign_en_out = 1'b0;

        mulresp_val = 1'b1;
      end
    endcase
  end

endmodule

module unsign #( parameter W = 1 )
(
  input     [W-1:0] in,
  output    [W-1:0] out
);

  assign out = ( in[W-1] ) ? (~in + 1'b1) : in;

endmodule

module UnsignExtendA
(
  input   [31:0]      in,
  output  [63:0]      out
);

  wire      [31:0] unsigned_a;
  
  unsign#(32) a_unsigner 
  (
    .in               (in),
    .out              (unsigned_a)
  );

  vc_ZeroExtend#(32, 64) extend_a 
  (
    .in       (unsigned_a),
    .out      (out)
  );

endmodule

module sign #( parameter W = 1)
(
  input   [W-1:0] in,
  output  [W-1:0] out
);

  assign out = ~in + 1'b1;

endmodule

`endif
