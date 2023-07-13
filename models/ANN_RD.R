library(tidyverse)
library(keras)
library(readr)

#BUILD ANN using PYT TP ##

## create GRM ##

## create GRM ##
geno <- as.matrix(TrainingGeno)
GM <- tcrossprod(geno)/dim(geno)
LG <- GM

Y <- as.matrix(TrainingPheno)
X = LG

X <- as.matrix(TrainingGeno)
Y <- as.matrix(TrainingPheno)

train_index <- sample(1:nrow(Y), min(1000, 0.75 * nrow(Y)))
X_train <- X[train_index, ]
Y_train <- Y[train_index,]

X_test <- X[-train_index, ]
Y_test <- Y[-train_index, ]


## Build model using pipe operator ##
N_Units = ncol(X_train)
No_Epoch = 100


build_model <- function() {
  model <- keras_model_sequential()
  model %>%
    layer_dense(units =N_Units, activation = "relu", input_shape = c(dim
                                                                     (X_train)[2])) %>%
    layer_dropout(rate = 0.5) %>%
    layer_dense(units = 1, activation = "linear")
  model %>% compile(
    loss = "mse",
    optimizer = "rmsprop",
    metrics = c("mse"))
  model}

## build and view model ##

model <- build_model()
model %>% summary()

## inner training and validation ##

model_fit <- model %>% fit(
  X_train, Y_train,
  shuffle=F,
  epochs = No_Epoch, batch_size = 10,
  validation_split = 0.2,
  verbose = 0)

## Refit model using early stopping ##

early_stop <- callback_early_stopping(monitor="val_loss", mode='min', patience =50)

model_Final <- build_model()
model_fit_Final <- model_Final%>%fit(
  X, Y,
  shuffle=F,
  epochs = No_Epoch, batch_size=10,
  validation_split = 0.2,
  verbose=0, callbacks = list(early_stop)
)
