module tb_cpu;
    logic clock;
    logic reset;
    
    single_port_ram_port_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_if(clock);

    single_port_ram #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_inst (
        .clk(clock),
        .a(mem_if.MEM)
    );

    cpu cpu (
        .clock(clock),
        .reset(reset),
        .mem_port(mem_if.CPU)
    );
    
    initial begin
        clock = 0;
        forever #5 clock = ~clock; 
    end
    
    initial begin
        $display("=== INICIANDO SIMULACAO ===");

        // FASE 1: RESET
        reset = 1;
        repeat (5) @(posedge clock);
        reset = 0;
        $display("Reset liberado em t=%0t", $time);

        
        // FASE 2: INICIALIZAR REGISTRADORES
        $display("=== INICIALIZANDO REGISTRADORES ===");
        force cpu.rb_inst.regs[0] = 32'h00000000;  
        force cpu.rb_inst.regs[1] = 32'h00000003;  
        force cpu.rb_inst.regs[2] = 32'h00000007;  
        @(posedge clock);
        release cpu.rb_inst.regs[0];
        release cpu.rb_inst.regs[1];
        release cpu.rb_inst.regs[2];
        $display("R0=%h, R1=%h, R2=%h", cpu.rb_inst.regs[0], cpu.rb_inst.regs[1], cpu.rb_inst.regs[2]);

        // FASE 3: EXECUÇÃO
        $display("=== MONITORANDO EXECUCAO ===");
        repeat (40) @(posedge clock); 

        // FASE 4: RESULTADOS
        $display("=== RESULTADOS FINAIS ===");
        $display("PC final: %h", cpu.PC);
        $display("Estado final: %s", cpu.current_state.name());
        for (int i = 0; i < 10; i++) begin
            $display("R%0d = %h", i, cpu.rb_inst.regs[i]);
        end

        $display("*** TESTE FINALIZADO - VERIFIQUE OS REGISTRADORES PARA TODAS AS OPERACOES ***");

        $stop; 
    end

    logic [15:0] last_pc = 16'hFFFF;
    logic [1:0]  last_state = 2'b11;
    always @(posedge clock) begin
        if (!reset && (cpu.PC != last_pc || cpu.current_state != last_state)) begin
            $display("T:%0t | %s | PC:%h | Instr:%h | rdata:%h", 
                     $time, cpu.current_state.name(), cpu.PC, 
                     cpu.instrucao_atual, cpu.mem_port.rdata);
            last_pc    = cpu.PC;
            last_state = cpu.current_state;
        end
    end


endmodule
