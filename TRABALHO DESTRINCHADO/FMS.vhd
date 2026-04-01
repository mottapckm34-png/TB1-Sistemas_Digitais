library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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