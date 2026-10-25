class fifo_test extends uvm_test;

  `uvm_component_utils(fifo_test)

  virtual fifo_if vif;
  fifo_env env;

  function new(string name = "fifo_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);        
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface was not configured")
    end
    uvm_config_db #(virtual fifo_if)::set(this, "env.agent", "vif", vif);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_write_seq   wr_seq;
    fifo_read_seq    rd_seq;
    fifo_rand_sequence rnd_seq;
    
    phase.raise_objection(this);
    
	wr_seq = fifo_write_seq::type_id::create("wr_seq");
    wr_seq.num = 10;
    wr_seq.start(env.agent.seqr);

    rd_seq = fifo_read_seq::type_id::create("rd_seq");
    rd_seq.num = 10;
    rd_seq.start(env.agent.seqr);

    rnd_seq = fifo_rand_sequence::type_id::create("rnd_seq");
    rnd_seq.start(env.agent.seqr);

    rd_seq = fifo_read_seq::type_id::create("rd_seq2");
    rd_seq.num = 10;
    rd_seq.start(env.agent.seqr);

    repeat (5) @(posedge vif.clk);
    
    phase.drop_objection(this);
  endtask

endclass
