//========================================================================
// Test for MulDiv Unit
//========================================================================

`include "imuldiv-MulDivReqMsg.v"
`include "imuldiv-IntMulDivIterative.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module imuldiv_IntMulDivIterative_helper
(
  input       clk,
  input       reset,
  output      done
);

  wire [66:0] src_msg;
  wire  [2:0] src_msg_fn;
  wire [31:0] src_msg_a;
  wire [31:0] src_msg_b;
  wire        src_val;
  wire        src_rdy;
  wire        src_done;

  wire [63:0] sink_msg;
  wire        sink_val;
  wire        sink_rdy;
  wire        sink_done;

  assign done = src_done && sink_done;

  vc_TestSource#(67,3) src
  (
    .clk   (clk),
    .reset (reset),
    .bits  (src_msg),
    .val   (src_val),
    .rdy   (src_rdy),
    .done  (src_done)
  );

  imuldiv_MulDivReqMsgFromBits msgfrombits
  (
    .bits (src_msg),
    .func (src_msg_fn),
    .a    (src_msg_a),
    .b    (src_msg_b)
  );

  imuldiv_IntMulDivIterative imuldiv
  (
    .clk                   (clk),
    .reset                 (reset),
    .muldivreq_msg_fn      (src_msg_fn),
    .muldivreq_msg_a       (src_msg_a),
    .muldivreq_msg_b       (src_msg_b),
    .muldivreq_val         (src_val),
    .muldivreq_rdy         (src_rdy),
    .muldivresp_msg_result (sink_msg),
    .muldivresp_val        (sink_val),
    .muldivresp_rdy        (sink_rdy)
  );

  vc_TestSink#(64,3) sink
  (
    .clk   (clk),
    .reset (reset),
    .bits  (sink_msg),
    .val   (sink_val),
    .rdy   (sink_rdy),
    .done  (sink_done)
  );

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module tester;

  // VCD Dump
  initial begin
    $dumpfile("imuldiv-IntMulDivIterative.vcd");
    $dumpvars;
  end

  `VC_TEST_SUITE_BEGIN( "imuldiv-IntMulDivIterative" )

  reg  t0_reset = 1'b1;
  wire t0_done;

  imuldiv_IntMulDivIterative_helper t0
  (
    .clk   (clk),
    .reset (t0_reset),
    .done  (t0_done)
  );

  `VC_TEST_CASE_BEGIN( 1, "mul" )
  begin

    t0.src.m[ 0] = 67'h0_00000000_00000000; t0.sink.m[ 0] = 64'h00000000_00000000;
    t0.src.m[ 1] = 67'h0_00000001_00000001; t0.sink.m[ 1] = 64'h00000000_00000001;
    t0.src.m[ 2] = 67'h0_ffffffff_00000001; t0.sink.m[ 2] = 64'hffffffff_ffffffff;
    t0.src.m[ 3] = 67'h0_00000001_ffffffff; t0.sink.m[ 3] = 64'hffffffff_ffffffff;
    t0.src.m[ 4] = 67'h0_ffffffff_ffffffff; t0.sink.m[ 4] = 64'h00000000_00000001;
    t0.src.m[ 5] = 67'h0_00000008_00000003; t0.sink.m[ 5] = 64'h00000000_00000018;
    t0.src.m[ 6] = 67'h0_fffffff8_00000008; t0.sink.m[ 6] = 64'hffffffff_ffffffc0;
    t0.src.m[ 7] = 67'h0_fffffff8_fffffff8; t0.sink.m[ 7] = 64'h00000000_00000040;
    t0.src.m[ 8] = 67'h0_0deadbee_10000000; t0.sink.m[ 8] = 64'h00deadbe_e0000000;
    t0.src.m[ 9] = 67'h0_deadbeef_10000000; t0.sink.m[ 9] = 64'hfdeadbee_f0000000; 

    // add upper bit multiplication tests :(
    t0.src.m[10] = 67'h0_00010000_00010000; t0.sink.m[10] = 64'h00000001_00000000;
    t0.src.m[11] = 67'h0_ffff0000_ffff0000; t0.sink.m[11] = 64'h00000001_00000000;
    t0.src.m[12] = 67'h0_00010000_ffff0000; t0.sink.m[12] = 64'hffffffff_00000000; 

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 2, "div/rem" )
  begin

    t0.src.m[ 0] = 65'h1_00000000_00000001; t0.sink.m[ 0] = 64'h00000000_00000000;
    t0.src.m[ 1] = 65'h1_00000001_00000001; t0.sink.m[ 1] = 64'h00000000_00000001;
    t0.src.m[ 2] = 65'h1_00000000_ffffffff; t0.sink.m[ 2] = 64'h00000000_00000000;
    t0.src.m[ 3] = 65'h1_ffffffff_ffffffff; t0.sink.m[ 3] = 64'h00000000_00000001;
    t0.src.m[ 4] = 65'h1_00000222_0000002a; t0.sink.m[ 4] = 64'h00000000_0000000d;
    t0.src.m[ 5] = 65'h1_0a01b044_ffffb146; t0.sink.m[ 5] = 64'h00000000_ffffdf76;
    t0.src.m[ 6] = 65'h1_00000032_00000222; t0.sink.m[ 6] = 64'h00000032_00000000;
    t0.src.m[ 7] = 65'h1_00000222_00000032; t0.sink.m[ 7] = 64'h0000002e_0000000a;
    t0.src.m[ 8] = 65'h1_0a01b044_ffffb14a; t0.sink.m[ 8] = 64'h00003372_ffffdf75;
    t0.src.m[ 9] = 65'h1_deadbeef_0000beef; t0.sink.m[ 9] = 64'hffffda72_ffffd353;
    t0.src.m[10] = 65'h1_f5fe4fbc_00004eb6; t0.sink.m[10] = 64'hffffcc8e_ffffdf75;
    t0.src.m[11] = 65'h1_f5fe4fbc_ffffb14a; t0.sink.m[11] = 64'hffffcc8e_0000208b;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 3, "mixed" )
  begin

    t0.src.m[ 0] = 67'h0_fffffff8_00000008; t0.sink.m[ 0] = 64'hffffffff_ffffffc0;
    t0.src.m[ 1] = 67'h0_fffffff8_fffffff8; t0.sink.m[ 1] = 64'h00000000_00000040;
    t0.src.m[ 2] = 67'h0_0deadbee_10000000; t0.sink.m[ 2] = 64'h00deadbe_e0000000;
    t0.src.m[ 3] = 67'h0_deadbeef_10000000; t0.sink.m[ 3] = 64'hfdeadbee_f0000000;
    t0.src.m[ 4] = 65'h1_0a01b044_ffffb14a; t0.sink.m[ 4] = 64'h00003372_ffffdf75;
    t0.src.m[ 5] = 65'h1_deadbeef_0000beef; t0.sink.m[ 5] = 64'hffffda72_ffffd353;
    t0.src.m[ 6] = 65'h1_f5fe4fbc_00004eb6; t0.sink.m[ 6] = 64'hffffcc8e_ffffdf75;
    t0.src.m[ 7] = 65'h1_f5fe4fbc_ffffb14a; t0.sink.m[ 7] = 64'hffffcc8e_0000208b;

    // Add entries for divu/remu here
    t0.src.m[ 8] = 67'h2_00000000_00000001; t0.sink.m[ 8] = 64'h00000000_00000000;  // just make sure it works
    t0.src.m[ 9] = 67'h2_00000008_00000002; t0.sink.m[ 9] = 64'h00000000_00000004;
    t0.src.m[10] = 67'h2_0000000B_00000003; t0.sink.m[10] = 64'h00000002_00000003;
    t0.src.m[11] = 67'h2_00000001_fffffffe; t0.sink.m[11] = 64'h00000001_00000000;  // reinterpret 2s complement (divisor)
    t0.src.m[12] = 67'h4_ffffffff_00000002; t0.sink.m[12] = 64'h00000001_7fffffff;  // reinterpret 2s complement (dividend)
    t0.src.m[13] = 67'h2_fffffff8_fffffffe; t0.sink.m[13] = 64'hfffffff8_00000000;  // reinterpret 2s complement (both)

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

   //---------------------------------------------------------------------
   // Add More Test Cases Here
   //---------------------------------------------------------------------

  `VC_TEST_SUITE_END( 3 /* replace with number of test cases */ )

endmodule
