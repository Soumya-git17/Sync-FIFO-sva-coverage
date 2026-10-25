class fifo_seq_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_seq_item)
  
  rand bit w_en;
  rand bit r_en;
  rand bit [7:0] data_in;
  
  bit [7:0] data_out;
  bit full;
  bit empty;

  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction
  
  function string convert2string();
        return $sformatf("w_en=%0b r_en=%0b data_in=0x%02h | data_out=0x%02h full=%0b empty=%0b", w_en, r_en, data_in, data_out, full, empty);
    endfunction

endclass
