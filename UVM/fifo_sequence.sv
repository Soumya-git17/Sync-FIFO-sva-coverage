class fifo_write_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_write_seq)
  int unsigned num = 10;

  function new(string name = "fifo_write_seq");
    super.new(name);
  endfunction

  task body();
    fifo_seq_item req;
    repeat (num) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { w_en == 1; r_en == 0; })
        `uvm_fatal("RANDFAIL", "Transaction randomizer failed")
      finish_item(req);
    end
  endtask
endclass


class fifo_read_seq extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_read_seq)
  int unsigned num = 10;

  function new(string name = "fifo_read_seq");
    super.new(name);
  endfunction

  task body();
    fifo_seq_item req;
    repeat (num) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { w_en == 0; r_en == 1; })
        `uvm_fatal("RANDFAIL", "Transaction randomizer failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_rand_sequence extends uvm_sequence #(fifo_seq_item);

  `uvm_object_utils(fifo_rand_sequence)
  int unsigned num = 10;

  function new(string name = "fifo_rand_sequence");
    super.new(name);
  endfunction

  task body();
    fifo_seq_item req;
    repeat (num) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      
      if (!req.randomize() with {
        w_en dist {1 := 60, 0 := 40};
        r_en dist {1 := 50, 0 := 50};
      }) begin
        `uvm_fatal("RANDFAIL", "Transaction randomizer failed")
      end
      
      finish_item(req);
    end
  endtask

endclass