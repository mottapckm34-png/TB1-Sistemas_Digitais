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
	 
end Behavioral;