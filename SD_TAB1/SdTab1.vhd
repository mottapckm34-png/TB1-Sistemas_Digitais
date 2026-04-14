library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =========================================================================
-- DEBAUNCER
-- =========================================================================

entity debauncer is
    port (
        -- INPUT
        clk         : in STD_LOGIC; -- Clock de 50 Mhz da placa, para saber qunado o botão "parou" de vibrar.
        rst         : in STD_LOGIC; -- Botão de reset. Reinicia o código todo.
        btn_in      : in STD_LOGIC; -- Botão de entrada de sinal

        --OUTPUT
        btn_pulse   : out STD_LOGIC -- Saida de sinal para a placa, saida já limpa
    );
end debauncer;

architecture Behavioral of debauncer is
    constant MAX_COUNT : integer := 1_000_000;                     -- Tempo que o circuito vai esperar até ter certeza que parou de trpidar
    signal sync : std_logic_vector (1 downto 0) := (others => '0'); -- Barramento de 2 bits, garante que o aperto seja lido ritmica, a placa altera rapidante energia entre 1 e 0, e essees dois FFs vai fazer a limpagem, (others => '0') essa parte garante que quando ligar a placa seja 00.
    signal btn_stable : std_logic := '0';                           -- Linha de conexão entre componentes que inicializa em 1, ele limpa  efiltra o botão, passando a ser 1 qunado tem 100% de certeza que foi pressionado o btn
    signal btn_prev : std_logic := '0';                             -- Armazena o estado anterior do botão para detectar mudanças
    signal count : integer range 0 to MAX_COUNT := 0;               -- Contador para medir o tempo de estabilidade do botão
    
	begin

 -- Stage 1: Two-flip-flop synchronizer
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync <= (others => '0'); -- Reset dos flip-flops
            else
                sync(0) <= btn_in;       -- Primeiro flip-flop captura o sinal do botão
                sync(1) <= sync(0);     -- Segundo flip-flop sincroniza o sinal ao clock
            end if;
        end if;
    end process;

 -- Stage 2: Stability counter
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= 0;             -- Reset do contador
                btn_stable <= '0';      -- Reset do sinal de estabilidade
            elsif sync(1) /= btn_stable then  -- Sinal mudou: conta ciclos ate estabilizar
                if count = MAX_COUNT then
                    btn_stable <= sync(1); -- Aceita o novo nivel apos 20 ms
                    count      <= 0;
                else
                    count <= count + 1;
                end if;
            else
                -- Sinal igual ao nivel aceito: qualquer glitch reinicia
                count <= 0;
            end if;
        end if;
    end process;

 -- Stage 3: Rising-edge pulse generator
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                btn_prev  <= '0';
                btn_pulse <= '0';
            else
                btn_prev  <= btn_stable;
                btn_pulse <= btn_stable and (not btn_prev); -- Detecta borda 0->1
            end if;
        end if;
    end process;

end Behavioral;

-- =========================================================================
-- ULA - SELEÇÃO DE OPERAÇÃO ADIÇÃO, SUBTRAÇÃO, AND, OR, NOT, XOR, SHIFT L, SHIFT R "main" DO PROJETO
-- =========================================================================

entity ULA is
    port (
        -- ENTRADAS / INPUT
        op        :  in STD_LOGIC_VECTOR (2 downto 0); -- OPERATION SELECTION 3 BIT, 000, 001, 010, 011, 100, 101, 110 ,111
        a         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY
        b         :  in STD_LOGIC_VECTOR (3 downto 0); -- NUMBER IN BINARY

        -- SAIDAS / OUTPUT
        result    :  out STD_LOGIC_VECTOR (3 downto 0); -- RESULT NUMBER IN BINARY
        flag_z    :  out std_logic; -- FLAG RESULT NUMBER 0
        flag_n    :  out std_logic; -- FLAG RESULT NUMBER NEGATIV
        flag_c    :  out std_logic; -- FLAG CARRY OUT
        flag_ov   :  out std_logic -- FLAG OVERFLOW
    );
end ULA;

architecture Behavioral of ULA is
    signal rest5 : STD_LOGIC_VECTOR (4 downto 0); -- CAPTURE THE CARRY AND SHIFT OUT IN 4 BIT

begin

    process(a, b, op)
        variable ext_a              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable ext_b              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable tempResult         : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
        variable shiftt_amt : integer range 0 to 15;         -- NEW: converte o operando B em inteiro para controlar a quantidade de shifts
                                                             -- Intervalo 0 a 15 cobre todos os valores possiveis de um vetor de 4 bits

    begin
        ext_a      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
        ext_b      := unsigned ('0' & b);       -- Concatenarion, places a '0' in front of every bit
        tempResult := (others => '0');          -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

        case op is

            -- Soma a complemento de 2
            when "000" => tempResult := ext_a + ext_b;   

            -- Subtração a complemento de 2, COMPLEMENTO A 2: A + (-B) + 1, to_unsigned (1, 5) representa a soma +1, gera um valor número 1 de tamanho de 5 bits
            when "001" => tempResult := ext_a + (NOT ext_b) + to_unsigned (1, 5); 
        
            -- AND, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
            when "010" => tempResult := '0' & (unsigned(a) AND unsigned(b)); 

            -- OR, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
            when "011" => tempResult := '0' & (unsigned(a) OR unsigned(b));

            -- XOR: bit a bit
            when "100" => tempResult := '0' & (unsigned(a) xor unsigned(b));
 
            -- NOT: complemento de A (B ignorado)
            when "101" => tempResult := '0' & (not unsigned(a));
 
            ----------------------------------------------------------------
            -- SHL: deslocamento logico a ESQUERDA
            --
            -- Operando A = numero que sera deslocado
            -- Operando B = quantidade de casas (controlado por shift_amt)
            --
            -- Logica de controle:
            --   shift_amt converte B para inteiro.
            --   O case seleciona qual fatia de A forma o resultado e qual bit
            --   de A foi o ultimo a sair pelo lado esquerdo (vai para carry).
            --
            --   Deslocamento N para a esquerda:
            --     resultado  = a(3-N downto 0) concatenado com N zeros a direita
            --     carry      = a(4-N), o ultimo bit que saiu pelo MSB
            --
            --   N=0 : sem deslocamento, carry=0
            --   N=1 : resultado = a(2:0) & '0',     carry = a(3)
            --   N=2 : resultado = a(1:0) & "00",    carry = a(2)
            --   N=3 : resultado = a(0)  & "000",    carry = a(1)
            --   N=4 : resultado = "0000",            carry = a(0)
            --   N>4 : resultado = "0000",            carry = '0'
            -- SHL: deslocamento a esquerda — MSB vai para carry (bit 4)
            when "110" =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- sem deslocamento
                    when 1 =>
                        tempResult(4)          := a(3);            -- carry = MSB
                        tempResult(3 downto 0) := unsigned(a(2 downto 0) & '0');
                    when 2 =>
                        tempResult(4)          := a(2);            -- carry = bit 2
                        tempResult(3 downto 0) := unsigned(a(1 downto 0) & "00");
                    when 3 =>
                        tempResult(4)          := a(1);            -- carry = bit 1
                        tempResult(3 downto 0) := unsigned(a(0) & "000");
                    when 4 =>
                        tempResult(4)          := a(0);            -- carry = LSB (ultimo a sair)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: tudo zerado
                        tempResult := (others => '0');
                end case;
 
            ----------------------------------------------------------------
            -- SHR: deslocamento logico a DIREITA
            --
            -- Operando A = numero que sera deslocado
            -- Operando B = quantidade de casas (controlado por shift_amt)
            --
            -- Logica de controle:
            --   Espelho do SHL, mas os bits saem pelo lado direito (LSB).
            --
            --   N=0 : sem deslocamento, carry=0
            --   N=1 : resultado = '0' & a(3:1),    carry = a(0)
            --   N=2 : resultado = "00" & a(3:2),   carry = a(1)
            --   N=3 : resultado = "000" & a(3),    carry = a(2)
            --   N=4 : resultado = "0000",           carry = a(3)
            --   N>4 : resultado = "0000",           carry = '0'
            -- SHR: deslocamento a direita — LSB vai para carry (bit 4)
            when others =>
                shift_amt := to_integer(unsigned(b));
                case shift_amt is
                    when 0 =>
                        tempResult := '0' & unsigned(a);           -- sem deslocamento
                    when 1 =>
                        tempResult(4)          := a(0);            -- carry = LSB
                        tempResult(3 downto 0) := unsigned('0' & a(3 downto 1));
                    when 2 =>
                        tempResult(4)          := a(1);            -- carry = bit 1
                        tempResult(3 downto 0) := unsigned("00" & a(3 downto 2));
                    when 3 =>
                        tempResult(4)          := a(2);            -- carry = bit 2
                        tempResult(3 downto 0) := unsigned("000" & a(3));
                    when 4 =>
                        tempResult(4)          := a(3);            -- carry = MSB (ultimo a sair)
                        tempResult(3 downto 0) := (others => '0');
                    when others =>                                 -- N > 4: tudo zerado
                        tempResult := (others => '0');
                end case;

        end case;

        rest5 <= std_logic_vector(tempResult); -- Act as a output signal, electric signal

end process;

-- OUTPUT

--resultado de 4 bits vai receber o sinal
result <= rest5 (3 downto 0);

--FLAG DE 0 - quando o resultado for 0000, ou seja, todos os bits sao 0
flag_z <= '1' when rest5 (3 downto 0) = "0000" else '0';

-- FLAG DE NUMEROS NEGATIVOS - quando o resultado da operação tem como resultado numeros negativos e necessita do complemento de 2
flag_n <=  rest5 (3);

--FLAG DE CARRY - quando necessitar do carry (vai um), a sequencia é ativa nos leds
flag_c <= rest5 (4);

-- FLAG DE OVERFLOW
-- ADD overflow
flag_ov <= 
    -- ADD overflow
        ((NOT (a(3) XOR b(3))) AND (a(3) XOR rest5(3))) when op = "000"
    else
    -- SUB overflow
        ((a(3) XOR b(3)) AND (a(3) XOR rest5(3))) when op = "001" 
    else
        '0'; -- Overflow undefined for logical/shift operations

end Behavioral;

-- =========================================================================
-- FMS - CONTROLE DE MEMÓRIA  
-- =========================================================================

entity fsm_controller is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_pulse   : in  STD_LOGIC;                      -- Sinal do botão de "Enter" (debounced)
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);   -- As 4 chaves seletoras da placa FPGA

        out_op      : out STD_LOGIC_VECTOR(2 downto 0);   -- Saída da operação (3 bits para a ULA)
        out_a       : out STD_LOGIC_VECTOR(3 downto 0);   -- Saída A (4 bits para a ULA)
        out_b       : out STD_LOGIC_VECTOR(3 downto 0);   -- Saída B (4 bits para a ULA)
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)    -- Saída para LEDs indicando o estado atual
    );
end fsm_controller;

architecture Behavioral of fsm_controller is

    type state_type is (S_WAIT_OP, S_WAIT_A, S_WAIT_B, S_COMPUTE);
    signal current_state : state_type := S_WAIT_OP;

    signal reg_op   : STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- Registrador para a operação
    signal reg_a    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Registrador para o operando A
    signal reg_b    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Registrador para o operando B

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= S_WAIT_OP;
                reg_op <= (others => '0');
                reg_a  <= (others => '0');
                reg_b  <= (others => '0');
            elsif btn_pulse = '1' then -- Transição de estado ocorre no pulso do botão
                case current_state is
                    when S_WAIT_OP =>
                            reg_op <= switches(2 downto 0); -- Captura os 3 bits menos significativos para a operação
                            current_state <= S_WAIT_A;

                    when S_WAIT_A =>
                        reg_a <= switches; -- Captura os 4 bits das chaves para o operando A
                        current_state <= S_WAIT_B;

                    when S_WAIT_B =>
                        reg_b <= switches; -- Captura os 4 bits das chaves para o operando B
                        current_state <= S_COMPUTE;

                    when S_COMPUTE =>
                        current_state <= S_WAIT_OP; -- Após exibir o resultado, retorna para aguardar nova operação

                    when others =>
                        current_state <= S_WAIT_OP; -- Proteção contra estados inválidos
                end case;
            end if;
        end if;
    end process;

    -- Conecta os registradores internos às saídas
    out_op <= reg_op;
    out_a  <= reg_a;
    out_b  <= reg_b;

    -- Decodificador para os LEDs de estado
    with current_state select
        state_out <= "00" when S_WAIT_OP,
                     "01" when S_WAIT_A,
                     "10" when S_WAIT_B,
                     "11" when S_COMPUTE,
                     "00" when others;

end Behavioral;

--============================================================================
-- TOP_LEVEL PINAGE
--============================================================================
entity top_level is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_in      : in  STD_LOGIC;
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);
        led         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end top_level;

architecture Structural of top_level is
--Internal wires

signal w_btn_pulse : STD_LOGIC;
signal w_op_code : STD_LOGIC_VECTOR(2 downto 0);
signal w_operando_a : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_b : STD_LOGIC_VECTOR(3 downto 0);
signal w_state_out : STD_LOGIC_VECTOR(1 downto 0);
signal w_result : STD_LOGIC_VECTOR(3 downto 0);
signal w_flag_zero : std_logic;
signal w_flag_neg : std_logic;
signal w_flag_carry : std_logic;
signal w_flag_ovf : std_logic;

begin

    --Debouncer instance: filters raw button input 
    U_DEB : entity work.debauncer
        port map (
            clk => clk,
            rst => rst,
            btn_in => btn_in,
            btn_pulse => w_btn_pulse
        );

--FSM Controller instance: manages the state transitions and captures inputs

    U_FSM : entity work.fsm_controller
        port map (
            clk => clk,
            rst => rst,
            btn_pulse => w_btn_pulse,
            switches => switches,
            out_op => w_op_code,
            out_a => w_operando_a,
            out_b => w_operando_b,
            state_out => w_state_out
        );


 --ALU instance: combinational computation
    U_ALU: entity work.ULA
        port map (
            op => w_op_code,
            a => w_operando_a,
            b => w_operando_b,
            result => w_result,
            flag_z => w_flag_zero,
            flag_n => w_flag_neg,
            flag_c => w_flag_carry,
            flag_ov => w_flag_ovf
        );

-- LED Outputs multiplexing
    p_led_mux : process(w_state_out, w_result,
                        w_flag_zero, w_flag_neg, w_flag_carry, w_flag_ovf)
    begin
        if w_state_out = "11" then
            -- Modo RESULTADO (S_COMPUTE): exibe resultado e flags
            led(3 downto 0) <= w_result;      -- bits do resultado
            led(4)          <= w_flag_zero;   -- flag Zero
            led(5)          <= w_flag_neg;    -- flag Negativo
            led(6)          <= w_flag_carry;  -- flag Carry
            led(7)          <= w_flag_ovf;    -- flag Overflow
        else
            -- Modo ENTRADA: exibe estado atual nos 2 LEDs inferiores
            -- w_state_out = "00" aguardando op | "01" aguardando A | "10" aguardando B
            led(1 downto 0) <= w_state_out;   -- estado nos LEDs 0 e 1
            led(7 downto 2) <= (others => '0'); -- demais LEDs apagados
        end if;
    end process p_led_mux;

end Structural;