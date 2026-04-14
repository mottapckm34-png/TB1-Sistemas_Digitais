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