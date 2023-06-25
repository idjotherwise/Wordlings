module Utils

using LinearAlgebra
using LoopVectorization

export cossim

"Compute cosine similarity between a word embedding and an index"
function cossim(v::Vector{T}, M, Mt) where {T}
  vn = norm(v)
  res = Vector{T}(undef, size(M, 1))
  mul!(res, M, v)
  @turbo for j in axes(Mt, 2)
    tmp = zero(T)
    for i in axes(Mt, 1)
      tmp += Mt[i, j]^2
    end
    tmp = sqrt(tmp) * vn
    res[j] = res[j] / tmp
  end
  res
end


end