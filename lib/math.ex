defmodule AEA.Math do
    def choose(n,k) when is_integer(n) and is_integer(k) and n>=0 and k>=0 and n>=k do
      if k==0, do: 1, else: choose(n,k,1,1)
    end

    def choose(n,k,k,acc), do: div(acc * (n-k+1), k)
    def choose(n,k,i,acc), do: choose(n, k, i+1, div(acc * (n-i+1), i))



#   Enum.reduce(m_gt..min(m_g, m_t), 0, fn(i, acc) ->
#       acc +
##        AEA.Math.choose(m_t, i) * AEA.Math.choose(m_tot - m_t, m_g - i) / AEA.Math.choose(m_tot, m_g)
#       :math.exp(
#         :math.log(AEA.Math.choose(m_t, i)) + :math.log(AEA.Math.choose(m_tot - m_t, m_g - i)) -
#         :math.log(AEA.Math.choose(m_tot, m_g))
#       )
#   end)
    def pval(m_gt, m_g, m_t, m_tot) do
      Enum.reduce m_gt..min(m_g, m_t), 0, fn(i, acc) ->
        acc + :math.exp(
            logsum(m_t - i + 1, m_t) +
            logsum(m_g - i + 1, m_g) +
            logsum(m_tot - m_g - m_t + i + 1, m_tot - m_g) -
            logsum(1, i) -
            logsum(m_tot - m_t + 1, m_tot)
        )
      end
    end

    def logsum(from, to) do
      Enum.reduce from..to, 0, fn(i, acc) ->
      	acc + :math.log(i)
      end
    end
end