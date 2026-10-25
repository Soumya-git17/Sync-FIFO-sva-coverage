class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)
    virtual fifo_if vif;
  uvm_analysis_port #(fifo_seq_item) ap;

    function new(string name = "fifo_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
      if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
          `uvm_fatal("NOVIF", "Virtual interface not configured for monitor")
      end
    endfunction

    task run_phase(uvm_phase phase);
      fifo_seq_item item;
      forever begin
        @(posedge vif.clk);
        	if (vif.rst_n) begin
              item = fifo_seq_item::type_id::create("item");
              item.w_en     = vif.w_en;
              item.r_en     = vif.r_en;
              item.data_in  = vif.data_in;
              item.data_out = vif.data_out;
              item.full     = vif.full;
              item.empty    = vif.empty;
              `uvm_info("MON", item.convert2string(), UVM_MEDIUM)
              ap.write(item);
            end
        end
    endtask

endclass