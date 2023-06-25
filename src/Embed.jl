module Embed

using ..Utils
using LinearAlgebra

export uk_embtable, ru_embtable, embeddings_index, word_indicies, read_embedding, get_embedding, get_similar_words, EmbeddingTable, Word2Vec, word_pairs

"""
Struct to hold the embedding values and the vocab
"""
struct EmbeddingTable{M<:AbstractMatrix,A<:AbstractVector}
  embeddings::M
  vocab::A
end

Base.convert(::Type{EmbeddingTable}, t::Tuple{<:AbstractMatrix,<:AbstractVector}) = EmbeddingTable(t...)

struct Word2Vec end


"""
Read the embeddings from a word2vec-style of file. First part of a line is the word/token, last part is the embedding vector.
First line of the file (the header) describes the dimensions for the vectors: for example 60000, 300 means 60000 words each with a
a 300-dimensional embedding vector.
"""
function read_embedding(::Type{Word2Vec}, embedding_file::String; keep_words::Vector{String}=String[], max_vocab_size::Union{Int64,Nothing}=nothing)::EmbeddingTable
  local LL, indexed_words, index
  if !isfile(embedding_file)
    embedding_file = "data/test_embeds.vec"
    max_vocab_size = 3
  end

  open(embedding_file, "r") do fh
    vocab_size, vector_size = parse.(Int64, split(readline(fh)))

    max_stored_vocab_size = isnothing(max_vocab_size) ? vocab_size : min(max_vocab_size, vocab_size)

    indexed_words = Vector{String}(undef, max_stored_vocab_size)
    LL = Array{Float32}(undef, vector_size, max_stored_vocab_size)

    index = 1
    @inbounds for _ in 1:vocab_size
      word = readuntil(fh, ' ', keep=false)
      vector = Vector{Float32}(undef, vector_size)
      vector = parse.(Float32, split(readline(fh), ' '))

      if !occursin("_", word) && (length(keep_words) == 0 || word in keep_words) #If it isn't a phrase
        LL[:, index] = vector ./ norm(vector)
        indexed_words[index] = word

        index += 1
        if index > max_stored_vocab_size
          break
        end
      end

    end
  end

  LL = LL[:, 1:index-1] #throw away unused columns
  indexed_words = indexed_words[1:index-1] #throw away unused columns
  LL, indexed_words
end

const uk_embtable = read_embedding(Word2Vec, "/Users/ifan/code/julia/cc.uk.300.vec")
const ru_embtable = read_embedding(Word2Vec, "/Users/ifan/code/julia/cc.ru.300.vec")

function embeddings_index(et::EmbeddingTable{Matrix{Float32},Vector{String}})::Matrix{Float32}
  copy(transpose(et.embeddings))
end

const WordIndicies = Dict{String,Int64}

"A function to create a look-up to connect a word with its index."
function word_indicies(embtable::EmbeddingTable{Matrix{Float32},Vector{String}})::WordIndicies
  Dict(word => ii for (ii, word) in enumerate(embtable.vocab))
end

const ru_lookup = word_indicies(ru_embtable)
const uk_lookup = word_indicies(uk_embtable)

"Get the vector associated with a word."
function get_embedding(word::String, lang::String)
  lookup_table = lang == "uk" ? uk_lookup : ru_lookup
  e_table = lang == "uk" ? uk_embtable : ru_embtable
  ind = lookup_table[word]
  e_table.embeddings[:, ind]
end

"List `topn` most similar words."
function get_similar_words(word::String, embtable::EmbeddingTable{Matrix{Float32},Vector{String}}; topn::Int64=5)::Vector
  word_embedding = get_embedding(word, embtable)
  indexes = embeddings_index(embtable)
  indexes_tr = embtable.embeddings
  sims = cossim(word_embedding, indexes, indexes_tr)
  idxs = partialsortperm(sims, 1:topn, rev=true)
  similarities = view(sims, idxs)
  similar_words = view(embtable.vocab, idxs)
  collect(zip(similar_words, similarities))
end

function word_pairs(filename::String)
  uk_ru_pairs = Vector{Tuple{String,String}}()
  uk_vectors = Vector{Vector{Float32}}()
  ru_vectors = Vector{Vector{Float32}}()
  filename = isfile(filename) ? filename : "data/test_shared_words.txt"
  open(filename, "r") do ps
    for l in eachline(ps)
      uk, ru = String.(split(l, "\t"))
      if uk ∉ uk_embtable.vocab || ru ∉ ru_embtable.vocab
        continue
      end
      push!(uk_ru_pairs, (uk, ru))
      push!(uk_vectors, get_embedding(uk, "uk"))
      push!(ru_vectors, get_embedding(ru, "ru"))
    end
  end
  uk_ru_pairs, uk_vectors, ru_vectors
end

end
