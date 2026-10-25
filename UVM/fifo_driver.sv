class fifo_driver extends uvm_driver #(fifo_seq_item);

  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;

  function new(string name = "fifo_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not configured for driver")
    end
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item req;

    vif.rst_n   = 0;
    vif.w_en    = 0;
    vif.r_en    = 0;
    vif.data_in = '0;

    repeat(2) @(posedge vif.clk);
    @(negedge vif.clk);
    vif.rst_n = 1;

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("DRV", $sformatf("Received transaction: w_en=%0b, r_en=%0b, data_in=%0h",
                                 req.w_en, req.r_en, req.data_in), UVM_MEDIUM)

      @(negedge vif.clk);
      vif.w_en = req.w_en;
      vif.r_en = req.r_en;
      vif.data_in = req.data_in;

      `uvm_info("DRV", "Driving transaction to FIFO", UVM_MEDIUM)

      @(negedge vif.clk);
      vif.w_en = 0;
      vif.r_en = 0;       

      seq_item_port.item_done();
    end
  endtask

endclass
