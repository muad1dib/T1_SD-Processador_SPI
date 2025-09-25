module tb_processador;
    logic clock;
    logic reset;
    
    single_port_ram_port_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_if(clock);

    single_port_ram #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) mem_inst (
        .clk(clock),
        .a(mem_if.MEM)
    );

    Processador cpu (
        .clock(clock),
        .reset(reset),
        .mem_port(mem_if.CPU)
    );
    
    initial begin
        clock = 0;
        forever #5 clock = ~clock; 
    end
    
    initial begin
        // ======================================
        // FASE 1: RESET E INICIALIZAÇÃO
        // ======================================
        $display("=== INICIANDO SIMULAÇÃO ===");
        
        reset = 1;
        
        force cpu.mem_port.en = 1'b0;
        force cpu.mem_port.we = 1'b0;
        
        #30; 
        
        // ======================================
        // FASE 2: CARREGAR INSTRUÇÕES (SEQUENCIALMENTE)
        // ======================================
        $display("=== CARREGANDO INSTRUÇÕES ===");
        
        release cpu.mem_port.en;
        release cpu.mem_port.we;
        
        @(posedge clock);
        
        mem_if.en = 1'b1;
        mem_if.we = 1'b1;
        mem_if.addr = 8'h00;
        mem_if.wdata = 32'h00001002;
        @(posedge clock);
        $display("Instrução 0 carregada: ADD R1,R0,R2 = %h no endereço %h", 32'h00001002, 8'h00);
        
        mem_if.addr = 8'h01;
        mem_if.wdata = 32'h00001312;
        @(posedge clock);
        $display("Instrução 1 carregada: SUB R3,R1,R2 = %h no endereço %h", 32'h00001312, 8'h01);
        
        mem_if.addr = 8'h02;
        mem_if.wdata = 32'h00002412;
        @(posedge clock);
        $display("Instrução 2 carregada: AND R4,R1,R2 = %h no endereço %h", 32'h00002412, 8'h02);
        
        mem_if.addr = 8'h03;
        mem_if.wdata = 32'h00000000;
        @(posedge clock);
        $display("Instrução 3 carregada: NOP = %h no endereço %h", 32'h00000000, 8'h03);
        
        mem_if.we = 1'b0;
        mem_if.en = 1'b0;
        
        // ======================================
        // FASE 3: INICIALIZAR REGISTRADORES
        // ======================================
        $display("=== INICIALIZANDO REGISTRADORES ===");
        
        force cpu.rb_inst.regs[0] = 32'h00000000;  // R0 = 0 (sempre zero)
        force cpu.rb_inst.regs[2] = 32'h00000007;  // R2 = 7 para testes
        
        @(posedge clock);
        @(posedge clock);
        
        release cpu.rb_inst.regs[0];
        release cpu.rb_inst.regs[2];
        
        $display("R0 = %h, R2 = %h", 32'h00000000, 32'h00000007);
        
        // ======================================
        // FASE 4: VERIFICAR MEMÓRIA
        // ======================================
        $display("=== VERIFICANDO MEMÓRIA ===");
        
        mem_if.en = 1'b1;
        mem_if.we = 1'b0;
        
        @(posedge clock);
        mem_if.addr = 8'h00;
        @(posedge clock);
        $display("Leitura memória[0] = %h", mem_if.rdata);
        
        mem_if.addr = 8'h01;
        @(posedge clock);
        $display("Leitura memória[1] = %h", mem_if.rdata);
        
        mem_if.addr = 8'h02;
        @(posedge clock);
        $display("Leitura memória[2] = %h", mem_if.rdata);
        
        mem_if.en = 1'b0;
        
        // ======================================
        // FASE 5: LIBERAR PROCESSADOR
        // ======================================
        $display("=== LIBERANDO PROCESSADOR ===");
        
        reset = 0;
        
        @(posedge clock);
        @(posedge clock);
        
        // ======================================
        // FASE 6: MONITORAR EXECUÇÃO
        // ======================================
        $display("=== MONITORANDO EXECUÇÃO ===");
        
        repeat(20) @(posedge clock);
        
        // ======================================
        // FASE 7: RESULTADOS FINAIS
        // ======================================
        $display("=== RESULTADOS FINAIS ===");
        $display("Tempo: %0t ps", $time);
        $display("PC final: %h", cpu.PC);
        $display("Estado final: %s", cpu.current_state.name());
        $display("");
        $display("Registradores:");
        $display("  R0 = %h (sempre zero)", cpu.rb_inst.regs[0]);
        $display("  R1 = %h (deveria ser 0+7=7)", cpu.rb_inst.regs[1]);  
        $display("  R2 = %h (inicializado com 7)", cpu.rb_inst.regs[2]);
        $display("  R3 = %h (deveria ser 7-7=0)", cpu.rb_inst.regs[3]);
        $display("  R4 = %h (deveria ser 7&7=7)", cpu.rb_inst.regs[4]);
        $display("");
        
        if (cpu.rb_inst.regs[1] == 32'h00000007 && 
            cpu.rb_inst.regs[3] == 32'h00000000 &&
            cpu.rb_inst.regs[4] == 32'h00000007) begin
            $display("*** TESTE PASSOU! PROCESSADOR FUNCIONANDO ***");
        end else begin
            $display("*** TESTE FALHOU - VERIFICAR IMPLEMENTAÇÃO ***");
        end
        
        $display("=== FIM DA SIMULAÇÃO ===");
    end
    
    logic [15:0] last_pc = 16'hFFFF;
    logic [1:0] last_state = 2'b11;
    
    always @(posedge clock) begin
        if (!reset && (cpu.PC != last_pc || cpu.current_state != last_state)) begin
            $display("T:%0t | %s | PC:%h | Instr:%h | rdata:%h", 
                     $time, cpu.current_state.name(), cpu.PC, 
                     cpu.instrucao_atual, cpu.mem_port.rdata);
            last_pc = cpu.PC;
            last_state = cpu.current_state;
        end
    end
    
    initial begin
        $dumpfile("processador.vcd");
        $dumpvars(0, tb_processador);
    end
    
endmodule