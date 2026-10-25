class fifo_agent extends uvm_agent;
  
  `uvm_component_utils(fifo_agent)
  
  uvm_sequencer #(fifo_seq_item) seqr;
  fifo_driver drv;
  fifo_monitor mon;
  virtual fifo_if vif;
  
  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name = "fifo_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer#(fifo_seq_item)::type_id::create("seqr", this);
    drv  = fifo_driver::type_id::create("drv", this);
    mon = fifo_monitor::type_id::create("mon", this); 
    ap = new("ap", this);

    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not configured for agent")
    end
        
    uvm_config_db#(virtual fifo_if)::set(this, "drv", "vif", vif);
    uvm_config_db#(virtual fifo_if)::set(this, "mon", "vif", vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    mon.ap.connect(ap);
  endfunction

endclass