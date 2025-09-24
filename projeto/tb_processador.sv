module tb_processador;

    logic clock;
    logic reset;

    dual_port_ram_port_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_if_a(clock);
    dual_port_ram_port_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_if_b(clock);

    dual_port_ram #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_inst (
        .clk(clock),
        .a(mem_if_a.MEM),
        .b(mem_if_b.MEM)
    );

    Processador cpu (
        .clock(clock),
        .reset(reset),
        .mem_a(mem_if_a.CPU),
        .mem_b(mem_if_b.CPU)
    );

    initial begin
        clock = 0;
        forever #5 clock = ~clock; 
    end

    initial begin
        reset = 1;
        #20;
        reset = 0;
        
        repeat(2) @(posedge clock);
        
        @(posedge clock);
        mem_if_a.wdata = 32'h00001000;
        mem_if_a.addr = 8'h00;
        mem_if_a.we = 1'b1;
        mem_if_a.en = 1'b1;
        
        @(posedge clock);
        mem_if_a.wdata = 32'h00001210;
        mem_if_a.addr = 8'h01;
        
        @(posedge clock);
        mem_if_a.wdata = 32'h00009312;
        mem_if_a.addr = 8'h02;
        
        @(posedge clock);
        mem_if_a.we = 1'b0;
        mem_if_a.en = 1'b0;
        
        @(posedge clock);
        
        repeat(50) @(posedge clock);
        
        $display("=== RESULTADOS DO TESTE ===");
        $display("Tempo: %0t", $time);
        if (cpu.rb_inst) begin
            $display("R0 = %h", cpu.rb_inst.regs[0]);
            $display("R1 = %h", cpu.rb_inst.regs[1]);
            $display("R2 = %h", cpu.rb_inst.regs[2]);
            $display("R3 = %h", cpu.rb_inst.regs[3]);
        end
        $display("PC = %h", cpu.PC);
        
        repeat(10) @(posedge clock);
        $finish;
    end

    always @(posedge clock) begin
        if (!reset) begin
            $display("Tempo: %0t | Estado: %s | PC: %h | Ciclo: %d", 
                     $time, cpu.current_state.name(), cpu.PC, cpu.cycle_counter);
        end
    end

    initial begin
        $dumpfile("processador.vcd");
        $dumpvars(0, tb_processador);
    end

endmodule
// Fazer
