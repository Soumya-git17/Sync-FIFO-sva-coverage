class fifo_env extends uvm_env;
  
  `uvm_component_utils(fifo_env)
  fifo_agent agent;
  fifo_scoreboard scb;

  function new(string name = "fifo_env", uvm_component parent = null);
    super.new(name, parent);        
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = fifo_agent::type_id::create("agent", this);
    scb = fifo_scoreboard::type_id::create("scb", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(scb.item_export);
  endfunction

endclass