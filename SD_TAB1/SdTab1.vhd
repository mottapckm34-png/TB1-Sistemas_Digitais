library IEEE;

use IEEE.STD_LOGIC.1164.ALL;
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
        btn_pulse   : out STD_LOGIC; -- Saida de sinal para a placa, saida já limpa
    );
end debauncer;

architecture Behavioral of debauncer is
    constant MAX_COUNT : interger := 1_000_000;                     -- Tempo que o circuito vai esperar até ter certeza que parou de trpidar
    signal sync : std_logic_vector (1 downto 0) := (others => '0'); -- Barramento de 2 bits, garante que o aperto seja lido ritmica, a placa altera rapidante energia entre 1 e 0, e essees dois FFs vai fazer a limpagem, (others => '0') essa parte garante que quando ligar a placa seja 00.
    signal btn_stable : std_logic := '0';                           -- Linha de conexão entre componentes que inicializa em 1, ele limpa  efiltra o botão, passando a ser 1 qunado tem 100% de certeza que foi pressionado o btn
    signal count : integer range 0 to MAX_COUNT := 0;               -- Contador para medir o tempo de estabilidade do botão
    signal btn_prev : std_logic := '0';                             -- Armazena o estado anterior do botão para detectar mudanças

    begin

 -- Stage 1: Two-flip-flop synchronizer
    process(clk, rst)
    begin
        if rst = '1' then
            sync <= (others => '0'); -- Reset dos flip-flops
        elsif rising_edge(clk) then
            sync(0) <= btn_in;       -- Primeiro flip-flop captura o sinal do botão
            sync(1) <= sync(0);     -- Segundo flip-flop sincroniza o sinal ao clock
        end if;
    end process;

 -- Stage 2: Stability counter
    process(clk, rst)
    begin
        if rst = '1' then
            count <= 0;             -- Reset do contador
            btn_stable <= '0';      -- Reset do sinal de estabilidade
            btn_prev <= '0';        -- Reset do estado anterior do botão
        elsif rising_edge(clk) then
            if sync(1) /= btn_prev then -- Detecta mudança no sinal do botão
                count <= 0;             -- Reinicia o contador se houver mudança
                btn_stable <= '0';      -- Sinal de estabilidade é desativado
                btn_prev <= sync(1);    -- Atualiza o estado anterior do botão
            else
                if count < MAX_COUNT then
                    count <= count + 1; -- Incrementa o contador se o sinal for estável
                else
                    btn_stable <= '1';  -- Ativa o sinal de estabilidade após tempo suficiente
                end if;
            end if;
        end if;
    end process;

 -- Stage 3: Rising-edge pulse generator
    process(clk, rst)
    begin
        if rst = '1' then
            btn_pulse <= '0';       -- Reset do pulso de saída
        elsif rising_edge(clk) then
            if btn_stable = '1' and sync(1) = '1' then -- Gera pulso quando o botão é estável e pressionado
                btn_pulse <= '1';
            else
                btn_pulse <= '0';   -- Caso contrário, mantém o pulso baixo
            end if;
        end if;
    end process;

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
        flag_ov   :  out std_logic; -- FLAG OVERFLOW
end ULA;

architecture Behavioral of ULA is
    signal rest5 : STD_LOGIC_VECTOR (4 downto 0); -- CAPTURE THE CARRY AND SHIFT OUT IN 4 BIT

process(a, b, op)
    variable ext_a              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
    variable ext_b              : unsigned (4 downto 0); -- Turn 4 bit into 5 bit
    variable tempResult         : unsigned (4 downto 0); -- Turn 4 bit into 5 bit

begin
    ext_a      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
    ext_b      := unsigned ('0' & a);       -- Concatenarion, places a '0' in front of every bit
    tempResult := unsigned (others => '0'); -- Take note of the result before send to the LEDS, "(others => '0')" this part will turn every bit in 0. This part of the code serves to avoid unwanted memory, trash;

    case op is

        -- Soma a complemento de 2
        when "000" => tempResult := ext_a + ext_b;   

        -- Subtração a complemento de 2, COMPLEMENTO A 2: A + (-B) + 1, to_unsigned (1, 5) representa a soma +1, gera um valor número 1 de tamanho de 5 bits
        when "001" => tempResult := ext_a + (NOT ext_b) + to_unsigned (1, 5); 
        
        -- AND, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
        when "010" => tempResult := '0' & (unsigned(a) AND unsigned(b)); 

        -- OR, '0' & Faz a concatenação obrigando a ter 5 bits, (unsigned(a) AND unsigned(b)) compara bit a bit, bit 0 de A com o bit 0 de B
        when "011" => tempResult := '0' & (unsigned(a) OR unsigned(b));

        -- CONTIAR AS OUTRAS OPERAÇÕES

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
        ((NOT (a(3) XOR b(3))) AND (a(3) XOR res5(3)))
            when op = "000" else
        -- SUB overflow
        ((a(3) XOR b(3)) AND (a(3) XOR res5(3)))
            when op = "001" else
        '0'; -- Overflow undefined for logical/shift operations

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
                        -- TRAVA DE SEGURANÇA: Só avança se for 000, 001, 010 ou 011
                        if switches(2 downto 0) = "000" or switches(2 downto 0) = "001" or switches(2 downto 0) = "010" or switches(2 downto 0) = "011" then
                            reg_op <= switches(2 downto 0); -- Captura os 3 bits menos significativos para a operação
                            current_state <= S_WAIT_A;
                        else
                            current_state <= S_WAIT_OP; -- Operação inválida, fica no mesmo estado
                        end if;

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

        result      : out STD_LOGIC_VECTOR(4 downto 0);
        flag_z      : out std_logic;
        flag_n      : out std_logic;
        flag_c      : out std_logic;
        flag_ov     : out std_logic;
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)
    );
end top_level;

architecture Structural of top_level is
-- Componentes
    component debauncer is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            btn_in      : in STD_LOGIC;
            btn_pulse   : out STD_LOGIC
        );
    end component;

    component ULA is
        port (
            op        :  in STD_LOGIC_VECTOR (2 downto 0);
            a         :  in STD_LOGIC_VECTOR (3 downto 0);
            b         :  in STD_LOGIC_VECTOR (3 downto 0);
            result    :  out STD_LOGIC_VECTOR (4 downto 0);
            flag_z    :  out std_logic;
            flag_n    :  out std_logic;
            flag_c    :  out std_logic;
            flag_ov   :  out std_logic
        );
    end component;

    component fsm_controller is
        port (
            clk         : in  STD_LOGIC;
            rst         : in  STD_LOGIC;
            btn_pulse   : in  STD_LOGIC;
            switches    : in  STD_LOGIC_VECTOR(3 downto 0);
            out_op      : out STD_LOGIC_VECTOR(2 downto 0);
            out_a       : out STD_LOGIC_VECTOR(3 downto 0);
            out_b       : out STD_LOGIC_VECTOR(3 downto 0);
            state_out   : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;


    --Componentes

componentes fsm_controller is
    port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        btn_pulse   : in  STD_LOGIC;
        switches    : in  STD_LOGIC_VECTOR(3 downto 0);
        out_op      : out STD_LOGIC_VECTOR(2 downto 0);
        out_a       : out STD_LOGIC_VECTOR(3 downto 0);
        out_b       : out STD_LOGIC_VECTOR(3 downto 0);
        state_out   : out STD_LOGIC_VECTOR(1 downto 0)
    );
end component;

component alu_4bit is
    port (
        op        :  in STD_LOGIC_VECTOR (2 downto 0);
        a         :  in STD_LOGIC_VECTOR (3 downto 0);
        b         :  in STD_LOGIC_VECTOR (3 downto 0);
        result    :  out STD_LOGIC_VECTOR (4 downto 0);
        flag_z    :  out std_logic;
        flag_n    :  out std_logic;
        flag_c    :  out std_logic;
        flag_ov   :  out std_logic
    );
end component;

--Internal wires

signal w_btn_pulse : STD_LOGIC;
signal w_op_code : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_a : STD_LOGIC_VECTOR(3 downto 0);
signal w_operando_b : STD_LOGIC_VECTOR(3 downto 0);
signal w_alu_enable : STD_LOGIC;
signal w_state_out : STD_LOGIC_VECTOR(2 downto 0);

signal w_result : STD_LOGIC_VECTOR(4 downto 0);
signal w_flag_zero : std_logic;
signal w_flag_neg : std_logic;
signal w_flag_carry : std_logic;
signal w_flag_ovf : std_logic;


begin

    --Debouncer instance: filters raw button input 
    generic map (
        DEBOUNCE_LIMIT => 500000 -- Adjust this value based on the expected debounce time and clock frequency(10MS at 50MHZ)
    )
    port map (
        clk => clk,
        rst => rst,
        btn_in => btn_in,
        btn_pulse => w_btn_pulse
    )
--FSM Controller instance: manages the state transitions and captures inputs

    U_FSM: fsm_controller
        port map (
            clk => clk,
            rst => rst,
            btn_pulse => w_btn_pulse,
            switches => switches,
            op_op => w_op_code,
            operando_a => w_operando_a,
            operando_b => w_operando_b,
            alu_enable => w_alu_enable,
            state_out => w_state
        );


 --ALU instance: combinational computation
 U_ALU: alu_4bit
    port map (
        op_code => w_op_code,
        operand_a => w_operando_a,
        operand_b => w_operando_b,
        result => w_result,
        flag_zero => w_flag_zero,
        flag_neg => w_flag_neg,
        flag_carry => w_flag_carry,
        flag_ovf => w_flag_ovf
    );

-- LED Outputs multiplexing
-- Whwn ALU result is active (S_SHOW_RESULT), display result and flags, otherwise show state
-- Otherwise, display the current state on the LEDs
    process(w_state, w_result, w_flag_zero, w_flag_neg, w_flag_carry, w_flag_ovf)

    begin


        if w_alu_enable = '1' then
            leds(4 downto 0) <= w_result; -- Display ALU result on LEDs

            leds(4) <= w_flag_zero; -- Display zero flag on LED 4
            leds(5) <= w_flag_neg;  -- Display negative flag on LED 5  
            leds(6) <= w_flag_carry; -- Display carry flag on LED 6
            leds(7) <= w_flag_ovf;  -- Display overflow flag on LED 7
        else

            --Imput mode: show current state on LEDs, upper LEDs off
            leds(3 downto 0) <= w_state_out; -- Display current state
            leds(3) <= '0'; -- Turn off upper LEDs
            leds(7 downto 4) <= (others => '0'); -- Turn off upper LEDs
        end if;
    end process;

end Structural;
