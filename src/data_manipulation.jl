# split data into train and test
"""
    partitionTrainTest(data, at)
Split a dataset into train and test datasets (array).
`at` ∈ [0, 1] adjusts the ratio of train and test data.
For example,
`at` = 0.8 implies train:test = 80:20.
"""
function partitionTrainTest(data, at)
    n = length(data)
    idx = Random.shuffle(1:n)
    train_idx = view(idx, 1:floor(Int, at*n))
    test_idx = view(idx, (floor(Int, at*n)+1):n)
    data[train_idx], data[test_idx]
end
