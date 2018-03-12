#------------------------------------------------------------------
#--------------    MODELING   -------------------------------------
#------------------------------------------------------------------



# Data Preprocessing:---------------- 
library(dplyr)
library(tidyr)

features = all_features

# calculate average amount for PA, DO amont type:
features$PA_amount = features$PA_amount/features$PA_count
features$DO_amount = features$DO_amount/features$DO_count

# turn PA Count into %, delete DO count
features$PA_count = features$PA_count/ features$frequency
features = select(features, -DO_count)
features = select(features, -total_amount)

# turn prefix into dummy variables 
library(dummies)
features = cbind(features,dummy(features$prefix))
features = select(features, -prefix)

# assign contact id as rowname, remove id
rownames(features) = features$contact_id
features = features[,-1]

# Turn time variable into numeric by removing "-"
features$last_act = as.numeric(gsub("[: -]", "" ,features$last_act, perl=TRUE))
features$zip_code = as.numeric(features$zip_code)

# turn all "NA" into "0":
features[is.na(features)] = 0   


View(features)




# TRAINING MODEL---------------------
calibration = subset.data.frame(features,calibration ==1)
prediction = subset.data.frame(features,calibration ==0)

View(calibration)
View(prediction)

#---Sampling--------------------------
set.seed(123)
train_ind = sample(seq_len(nrow(calibration)), size = 50000)

train = calibration[train_ind, ]
test = calibration[-train_ind, ]


#------------------------------------------------------------------
#--------------    SCORING  METHOD  -------------------------------
#------------------------------------------------------------------


#---------------Probability: Logit Model---------------------------
library(nnet)
library(caret)
library(MLmetrics)

prob_train = subset.data.frame(train, 
                              select=c(donation,min_amount,frequency,last_act,recency,
                                       PA_count,PA_amount,ch_MA,p_CH,p_CB,p_ES,active,
                                       freq_s1,sum_s1,freq_s2,sum_s2
                                      ))

prob_model = glm(formula = donation ~  .,
                      data = prob_train, family = "binomial")

prob_test = subset.data.frame(test, 
                              select=c(donation,min_amount,frequency,last_act,recency,
                                       PA_count,PA_amount,ch_MA,p_CH,p_CB,p_ES,active,
                                       freq_s1,sum_s1,freq_s2,sum_s2))

pred_prob = predict(prob_model,prob_test,type = "response")

pred_01 = rep(0,nrow(test))
pred_01[pred_prob>0.5] = 1

accuary_ProbModel = Accuracy(y_pred = pred_01, 
                             y_true = test$donation)
print (accuary_ProbModel)

#--------------Amount: linear regression-------------------------------
library(mlbench)

donnor_set = which(train$targetamount!=0)

# ----------- (1) linear regression:-----------------------------------

amount_model = glm(formula = log(targetamount) ~
                   log(sum_s2+1e-5)+
                    log(avg_amount+1e-5) + log(max_amount+1e-5) + log(min_amount+1e-5)
                  + PA_count +log(PA_amount+1e-5) +log(DO_amount+1e-5)
                  +DO_amount, data= train[donnor_set,])

summary(amount_model)

donnor_set_test = which(test$targetamount!=0)
test = test[donnor_set_test,]

pred_amount = exp(predict(amount_model,test))

library(rsq)
rsq.sse(amount_model)

#------------ (2) ridge regression------------------------------------
library(glmnet)

x = subset.data.frame(train, 
                      select = -c(calibration, donation))

# use log of all the amount to avoid extreme values
x = x[donnor_set,]
x$targetamount = log(x$targetamount+1e-5)
x$sum_s2 = log(x$sum_s2+1e-5)
x$avg_amount = log(x$avg_amount+1e-5)
x$max_amount = log(x$max_amount+1e-5)
x$PA_amount = log(x$PA_amount +1e-5)
x$DO_amount = log(x$DO_amount+1e-5)

y = x$targetamount
x = x[-1]
x =as.matrix(x)

lambdas = 10^seq(3, -2, by = -.1)

amount_model = cv.glmnet(x, y,
                   alpha = 0, lambda = lambdas)

# test set:
x_p = subset.data.frame(test, 
                        select = -c(targetamount,calibration, donation))

x_p$sum_s2 = log(x_p$sum_s2+1e-5)
x_p$avg_amount = log(x_p$avg_amount+1e-5)
x_p$max_amount = log(x_p$max_amount+1e-5)
x_p$PA_amount = log(x_p$PA_amount +1e-5)
x_p$DO_amount = log(x_p$DO_amount+1e-5)

donnor_set_test = which(test$targetamount!=0)
x_p = x_p[donnor_set_test,]
x_p = as.matrix(x_p)

y_p = predict(amount_model,x_p,type="response")

donnor_set_test = which(test$targetamount!=0)
test = test[donnor_set_test,]

# accuracy:
rsq = function(y,f) { 1 - sum((y-f)^2)/sum((y-mean(y))^2) }
rsq(test$targetamount,exp(y_p)) # 0.78


#---Ridge prediction----:
predX = subset.data.frame(prediction, 
                        select = -c(targetamount,calibration, donation))

predX$sum_s2 = log(predX$sum_s2+1e-5)
predX$avg_amount = log(predX$avg_amount+1e-5)
predX$max_amount = log(predX$max_amount+1e-5)
predX$PA_amount = log(predX$PA_amount +1e-5)
predX$DO_amount = log(predX$DO_amount+1e-5)

predX= as.matrix(predX)
predY = predict(amount_model,predX,type="response")
predY = exp(predY)

#------------------------------------------------------------------


#------------------------------------------------------------------
#--------------    RANDOM FOREST METHOD   -------------------------
#------------------------------------------------------------------

library (randomForest)

train_indrf = sample(seq_len(nrow(calibration)), size = 40000)

trainrf = calibration[train_indrf, ]
testrf = calibration[-train_indrf, ]

rf_trainset = subset.data.frame(trainrf, select = -c(calibration, donation))
rf_trainset$last_act = as.integer(rf_trainset$last_act)

rf_model = randomForest(targetamount ~ ., 
                        data = rf_trainset, 
                        ntree = 500,importance=TRUE,
                        proximity=TRUE,na.action=na.pass)

rf_predict = predict(object = rf_model, 
                     newdata = testrf,
                     type = "response")

rf_rsq = function(y,f) { 1 - sum((y-f)^2)/sum((y-mean(y))^2) }#Note 1
rf_rsq(testrf$targetamount,rf_predict)

summary(rf_model)



#------------------------------------------------------------------
#--------------    PREDICTION       -------------------------------
#------------------------------------------------------------------

out = data.frame(contact_id = rownames(prediction))

out$proba = predict(object = prob_model, 
                    newdata = prediction,
                    type = "response")

# (linear regressrion method:)
out$amount = exp(predict(object = amount_model,
                         newdata = prediction))
# (Ridge regression:)
# out$amount = predY

# (Random forest:)
# out$amount = rf_predict

out$score = out$proba * out$amount

one = which(out$score > 2)
out$solicitation = 0
out["solicitation"][one,]=1

sum_campaign = sum(out$score) - 2* length(which(out$solicitation == 1)) 
sum_campaign
  
View(out) 



#------------------------------------------------------------------
#--------------    EXPORT RESULT       ----------------------------
#------------------------------------------------------------------

result = cbind(as.character(out$contact_id),out$solicitation)
View(result)

write.table(result,quote = FALSE,row.names = FALSE,
            "mypaths/myfile.txt", sep="\t")





