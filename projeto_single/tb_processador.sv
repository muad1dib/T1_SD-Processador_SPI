module tb_processador;
    logic clock;
    logic reset;
    
    // Instância da interface de memória
    single_port_ram_port_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_if(clock);

    // Instância da memória (preenchida internamente com $readmemh ou initial)
    single_port_ram #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_inst (
        .clk(clock),
        .a(mem_if.MEM)
    );

    // Instância da CPU
    Processador cpu (
        .clock(clock),
        .reset(reset),
        .mem_port(mem_if.CPU)
    );
    
    // Clock de 10 unidades
    initial begin
        clock = 0;
        forever #5 clock = ~clock; 
    end
    
    initial begin
        $display("=== INICIANDO SIMULAÇÃO ===");

        // ======================================
        // FASE 1: RESET
        // ======================================
        reset = 1;
        repeat (5) @(posedge clock); // segura reset por 5 ciclos
        reset = 0;
        $display("Reset liberado em t=%0t", $time);

        // ======================================
        // FASE 2: INICIALIZAR REGISTRADORES
        // ======================================
        $display("=== INICIALIZANDO REGISTRADORES ===");
        force cpu.rb_inst.regs[0] = 32'h00000000;  // R0 = 0
        force cpu.rb_inst.regs[2] = 32'h00000007;  // R2 = 7
        @(posedge clock);
        release cpu.rb_inst.regs[0];
        release cpu.rb_inst.regs[2];
        $display("R0=%h, R2=%h", cpu.rb_inst.regs[0], cpu.rb_inst.regs[2]);

        // ======================================
        // FASE 3: EXECUÇÃO
        // ======================================
        $display("=== MONITORANDO EXECUÇÃO ===");
        repeat (40) @(posedge clock); // deixa rodar por 40 ciclos

        // ======================================
        // FASE 4: RESULTADOS
        // ======================================
        $display("=== RESULTADOS FINAIS ===");
        $display("PC final: %h", cpu.PC);
        $display("Estado final: %s", cpu.current_state.name());
        $display("R0=%h, R1=%h, R2=%h, R3=%h, R4=%h", 
                  cpu.rb_inst.regs[0],
                  cpu.rb_inst.regs[1],
                  cpu.rb_inst.regs[2],
                  cpu.rb_inst.regs[3],
                  cpu.rb_inst.regs[4]);

        if (cpu.rb_inst.regs[1] == 32'h00000007 && 
            cpu.rb_inst.regs[3] == 32'h00000000 &&
            cpu.rb_inst.regs[4] == 32'h00000007) begin
            $display("*** TESTE PASSOU! PROCESSADOR FUNCIONANDO ***");
        end else begin
            $display("*** TESTE FALHOU - VERIFICAR IMPLEMENTAÇÃO ***");
        end

        $finish;
    end

    // Monitor simplificado
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

    initial begin
        $dumpfile("processador.vcd");
        $dumpvars(0, tb_processador);
    end

endmodule
