class fifo_scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(fifo_scoreboard)
  
  uvm_analysis_imp #(fifo_seq_item, fifo_scoreboard) item_export;
  
  localparam int DEPTH = 8;
  bit [7:0] model[$];
  bit [7:0] exp_data_out;
  
  int checks, errors;
  int writes, reads, wr_blocked, rd_blocked;

  function new(string name = "fifo_scoreboard", uvm_component parent = null);
  	super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_export = new("item_export", this);
    exp_data_out = 0;
  endfunction
  
  function void write(fifo_seq_item item);
    bit do_wr, do_rd;
    bit exp_full, exp_empty;
    
    exp_full  = (model.size() == DEPTH);
    exp_empty = (model.size() == 0);
    checks++;
    
    if (item.data_out != exp_data_out) begin
      errors++;
      `uvm_error("SCB", $sformatf("data_out mismatch: exp=0x%02h got=0x%02h | %s", exp_data_out, item.data_out, item.convert2string()))
    end
    if (item.full !== exp_full) begin
      errors++;
      `uvm_error("SCB", $sformatf("full mismatch: exp=%0b got=%0b | %s", exp_full, item.full, item.convert2string()))
    end
    if (item.empty !== exp_empty) begin
      errors++;
      `uvm_error("SCB", $sformatf("empty mismatch: exp=%0b got=%0b | %s", exp_empty, item.empty, item.convert2string()))
    end
    
    do_wr = item.w_en && (model.size() < DEPTH);
    do_rd = item.r_en && (model.size() > 0);

    if (item.w_en && !do_wr) wr_blocked++;
    if (item.r_en && !do_rd) rd_blocked++;

    if (do_rd) begin
      exp_data_out = model.pop_front();
      reads++;
    end
    if (do_wr) begin
      model.push_back(item.data_in);
      writes++;
    end
    
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
	`uvm_info("SCB", $sformatf("Cycles checked=%0d  errors=%0d  writes=%0d  reads=%0d  blocked_wr=%0d  blocked_rd=%0d",
                               checks, errors, writes, reads, wr_blocked, rd_blocked), UVM_LOW)
    if (errors == 0 && checks > 0) `uvm_info("SCB", "TEST PASSED", UVM_LOW)
      else `uvm_info("SCB", "TEST FAILED", UVM_LOW)
  endfunction

endclass