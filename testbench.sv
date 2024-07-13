//TITLE: VIP FOR 8-BIT ALU
//DEVELOPED BY: AASHI SRIVASTAVA
//DATE: 12.07.24
//TOOL: ALDEC RIVIERA PRO
//—--------------------------------TRANSACTION CLASS—------------------------------------------------
class transaction;
  randc bit [7:0] in1,in2;
  randc bit [1:0] sel;
  bit [7:0] out;
  
  constraint data{in1>in2;
                  in1 inside{[0:10]};
                  in2 inside{[1:5]};}
  
  function void display(input string tag);
    $display($time,"[%s],in1=%0d,in2=%0d,sel=%0d,out=%0d",tag,in1,in2,sel,out);
  endfunction
endclass
//—-----------------------------------------------------------------------------------------------------------------

//—----------------------------------CONFIG CLASS----------------------------------------------------------
class cfg;
  static mailbox #(transaction) mbx_gen2drv=new();
  static mailbox #(transaction) mbx_mon2sco=new();
  static mailbox #(transaction) mbx_mon2cov=new();
endclass
//—-----------------------------------------------------------------------------------------------------------------


//—-------------------------------GENERATOR CLASS--------------------------------------------------
class generator;
  transaction t;
  mailbox #(transaction) mbx_gen2drv;
  event done,sconext;
  int count;
  
  function new(mailbox #(transaction) mbx_gen2drv);
    this.mbx_gen2drv=cfg::mbx_gen2drv;
    t=new();
  endfunction
  
  
  task run();
    repeat (count) begin
      t.randomize();
      mbx_gen2drv.put(t);
      t.display("GEN");
      @ sconext;
      end
    -> done;
  endtask
endclass
//—-----------------------------------------------------------------------------------------------------------------


//—------------------------------------------DRIVER CLASS--------------------------------------------------
class driver;
  transaction t;
  mailbox #(transaction) mbx_gen2drv;
  virtual intf add_if;
  
  function new(mailbox #(transaction) mbx_gen2drv);
    this.mbx_gen2drv=cfg::mbx_gen2drv;
  endfunction
  
  task run();
    forever begin
      mbx_gen2drv.get(t);
      @(posedge add_if.clk);
      add_if.in1<=t.in1;
      add_if.in2<=t.in2;
      add_if.sel<=t.sel;
      @(posedge add_if.clk);
      t.display("DRV");
    end
  endtask
endclass
//—-----------------------------------------------------------------------------------------------------------------

//—---------------------------------MONITOR CLASS--------------------------------------------------------
class monitor;
  transaction t;
  mailbox #(transaction) mbx_mon2sco;
  mailbox #(transaction) mbx_mon2cov;
  virtual intf add_if;
  event msco;
  
  function new(mailbox #(transaction) mbx_mon2sco,mailbox #(transaction) mbx_mon2cov);
    this.mbx_mon2sco=cfg::mbx_mon2sco;
    this.mbx_mon2cov=cfg::mbx_mon2cov;
    t=new();
  endfunction
  
  task run();
    forever begin
      repeat(4)
        @(posedge add_if.clk);
      t.out<=add_if.out;
      t.in1<=add_if.in1;
      t.in2<=add_if.in2;
      t.sel<=add_if.sel;
      @(posedge add_if.clk);
      mbx_mon2sco.put(t);
      mbx_mon2cov.put(t);
      t.display("MON");
      ->msco;
    end
  endtask
endclass
//—-----------------------------------------------------------------------------------------------------------------



//--------------------------------------------COVERAGE CLASS-------------------------------------------
class coverage;
  mailbox #(transaction) mbx_mon2cov;
  transaction t;
  
  covergroup cg;
    option.per_instance = 1;    // show bins in GUI & each instance coverage is collected separately
  //option.comment = Comment;   // Comment for each instance of CG
  type_option.strobe = 1;     // Sample at the end of the time slot
    coverpoint t.in1 { bins lower = {[0:$]}; }
    coverpoint t.in2 { bins lower = {[1:$]}; }
    coverpoint t.sel { bins sel_bins = {[0:3]}; }
  endgroup

  function new(mailbox #(transaction) mbx_mon2cov);
    this.mbx_mon2cov =cfg::mbx_mon2cov;
    cg = new();
  endfunction


  task run();
    forever begin
      mbx_mon2cov.get(t);
      cg.sample();
    end
  endtask
endclass
//—-----------------------------------------------------------------------------------------------------------------



//—---------------------------------SCOREBOARD CLASS--------------------------------------------------
class scoreboard;
  transaction t;
  mailbox #(transaction) mbx_mon2sco;
  event sconext,msco;
  
  function new(mailbox #(transaction) mbx_mon2sco);
    this.mbx_mon2sco=cfg::mbx_mon2sco;
  endfunction
  
  task run();
    forever begin
      mbx_mon2sco.get(t);
      wait (msco.triggered);
      
      //sel=0
      if(t.sel==2'b0)begin
        if(t.out==t.in1+t.in2)begin
          $display("[SCO] : Successfull additon");
        end
          else 
            $display("[SCO] : Unsuccessfull addition");
      end
      
      //sel=1
      else if(t.sel==2'd1)begin
        if(t.out==t.in1-t.in2)begin
          $display("[SCO] : Successful subtraction");
        end
        else 
          $display("[SCO] : Unsuccessfull subtraction");
      end
      
      //sel==2
      else if(t.sel==2'd2)begin
        if(t.out==t.in1*t.in2)begin
          $display("[SCO] : Successful multiplication");
        end
        else 
          $display("[SCO] : Unsuccessfull multiplication");
      end
      
      //sel=3
      else begin
        if(t.out==t.in1/t.in2) begin
          $display("[SCO] : Successful division");
        end
        else 
          $display("[SCO] : Unsuccessfull division");
      end
      $display("-----------------------------------------------");
      -> sconext;
      
    end
  endtask
  
endclass
//—-----------------------------------------------------------------------------------------------------------------


//—---------------------------ENVIRONMENT CLASS-------------------------------------------------------
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  coverage cov;
  mailbox #(transaction) mbx_gen2drv;
  mailbox #(transaction) mbx_mon2sco;
  mailbox #(transaction) mbx_mon2cov;
  virtual intf add_if;
  event next,next1;
  cfg c;
  
  function new(virtual intf add_if);
    this.add_if=add_if;
    c=new();
    gen=new(mbx_gen2drv);
    drv=new(mbx_gen2drv);
    mon=new(mbx_mon2sco,mbx_mon2cov);
    cov=new(mbx_mon2cov);
    sco=new(mbx_mon2sco);
    drv.add_if=this.add_if;
    mon.add_if=this.add_if;
    gen.sconext=next;
    sco.sconext=next;
    mon.msco=next1;
    sco.msco=next1;
  endfunction
  
  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
      cov.run();
    join_any
  endtask
endclass
//—-----------------------------------------------------------------------------------------------------------------

//—-----------------------------PROGRAM BLOCK-----------------------------------------------------------
program p(intf add_if);
  environment env;
  
  initial begin
   env=new(add_if);
   env.gen.count=10;
   env.run();
   wait(env.gen.done.triggered);
   $finish;
 end    
endprogram
//—-----------------------------------------------------------------------------------------------------------------
  
//—----------------------------MODULE BLOCK--------------------------------------------------------------
module tb();
  reg clk,rst;
  intf add_if(clk,rst);
   p p_dut(add_if);
  
  alu_8bit dut(.in1(add_if.in1), .in2(add_if.in2), .sel(add_if.sel), .out(add_if.out), .clk(clk), .rst(rst));
  
  initial
    clk<=0;
  
  always 
    #5 clk<=~clk;
  
endmodule
