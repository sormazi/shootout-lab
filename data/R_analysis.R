#### Penalty shoot-outs are tough, but the alternating order is fair ####

#### R script for the analysis ####

# by Silvan Vollmer #

## data set ##

data <- read.csv("data_final.csv", header = T)
str(data)

# matchday: the stage or round of the competition (e.g., "Final", "Semi-final", etc.)
# OfficialMatchName: the official name of the match
# FinalResult: the final result of the match
# player_name: the name of the player taking the penalty
# PenaltyTakerTeamName: the name of the team to which the penalty taker belongs
# outcome: the result of the penalty kick as recorded on transfermarkt (e.g., "scored", "missed")
# goalie_name: the name of the goalkeeper attempting to save the penalty
# GoalkeeperTeam: the team that the goalkeeper belongs to
# PenaltyMinute: the minute when the penalty was taken ("Pens" for shoot-outs)
# ScoreAfter: the score immediately after the penalty was taken
# CompetitionName: the file path that includes the name of the competition and season
# D1: indicator if the observation is in dataset D1 (see Fig.1)
# D2: indicator if the observation is in dataset D2 (see Fig.1)
# D3: indicator if the observation is in dataset D3 (see Fig.1)
# CompetitionShortName: an abbreviated name for the competition: national leages and cups (leag, cups), international club games (int), national team competitions (nat)
# SeasonID: a numeric identifier representing the season: 2012 is 2012-13
# homeTeamName: the name of the home team for the match
# awayTeamName: the name of the away team for the match
# TypePhaseName: the type of match phase the penalty was taken in (e.g., "Second half", "Penalty Shoot-Out"). If we only know that they occurred in the regular 90 mins: "in90".
# EventTypeName: the event type as defined for the analysis ("Goal", "Missed", "Save") for D3 and ("Goal", "Missed", "Save", "Not Scored") for D2
# ScoreBefore: the score immediately before the penalty was taken
# fcompMatchID: a unique identifier for the match 
# country: the country in which the match is taking place (e.g., "Albania")
# TournamentName: name of the tournament (e.g., "cups/albp-kupa-e-shqiperise"). For the european championships: nat_teams/int-em, world cup finals: nat_teams/int-wm
# order: order for penalty shoout-out (only defined for D2)

#### A. import libraries ####

library("ggplot2")
library("RColorBrewer")
library("ggpubr")
library("gridExtra")
library("zoo")
library("gridtext")
library("stringr")
library("xtable")

#### B. functions ####

# function to compute outcome rates #
# Arguments:
# dataset: either "D2" or "D3". (see Fig.1)
# cond: a logical vector representing additional conditions - must be the same length as the number of rows in 'data'
# digits: the number of decimal places to round the percentage rates to
outcome_function <- function(dataset="D3", cond=rep(TRUE,nrow(data)), digits=2){
	
	# check if the length of the 'cond' argument matches the number of rows in 'data'
	if (length(cond) != nrow(data)) {
		stop("The condition must have the same length as the data: 67310")  # error message
	}
	
	# create a row index based on dataset (D2 or D3) and any additional conditions
	row_id <- data[,dataset] & cond
	row_id[is.na(row_id)] <- FALSE
	
	# subset the data according to the row index
	subdata <- data[row_id,]
	
	# Calculate the percentage rates of each event type
	rates <- round(table(subdata$EventTypeName)/sum(table(subdata$EventTypeName))*100, digits = digits)

	data_output <- data.frame("n" = nrow(subdata), "goal" = rates["Goal"], "save" = rates["Save"], "miss" = rates["Missed"])
	rownames(data_output) <-""
	# output
	if(dataset == "D2"){
		return(data_output[,c("n","goal")])
	}
	if(dataset == "D3"){
		return(data_output)
	}
	
}

# function to count number of penalties #
# Arguments:
# dataset: the data frame/dataset
counting_function <- function(dataset=dataset){
	regulation <- c("Second half","First half", "in90")
	extra_time <- c("2nd Extra Time", "1st Extra Time")
	in_game <- c(regulation, extra_time)
	
	data_output <- data.frame("penalties" = nrow(dataset), 
														"regulation" = sum(dataset$TypePhaseName %in% regulation),
														"extra time" = sum(dataset$TypePhaseName %in% extra_time), 
														"in-game" = sum(dataset$TypePhaseName %in% in_game),
														"shootout" = sum(dataset$TypePhaseName == "Penalty Shoot-Out"))

	return(data_output)
}

#### C. missing values ####

colSums(is.na(data[data$D2,])) # goalie name, minute, score
colSums(is.na(data[data$D3,])) # goalie name, minute, score

#### Abstract ####

nrow(data)
nrow(data[data$D2,])
nrow(data[data$D3,])

nrow(data[data$D2 & data$TypePhaseName == "Penalty Shoot-Out",]) / nrow(data[data$D2,])
nrow(data[data$D3 & data$TypePhaseName == "Penalty Shoot-Out",]) / nrow(data[data$D3,])

length(unique(data[data$D2 & data$TypePhaseName == "Penalty Shoot-Out","fcompMatchID"]))


#### 2.  Materials and Methods ####

length(unique(data$TournamentName))

unique(data$SeasonID)

length(unique(data$TournamentName[data$CompetitionShortName =="leag"]))
length(unique(data$TournamentName[data$CompetitionShortName =="cups"]))
unique(data$TournamentName[!data$CompetitionShortName %in% c("cups", "leag")])

length(unique(data$CompetitionName))
nrow(data)


## 2.4  Summary and Data Analysis ##
regulation <- c("Second half","First half", "in90")
extra_time <- c("2nd Extra Time", "1st Extra Time")
in_game <- c(regulation, extra_time)

# table 1
sum(is.na(data$TypePhaseName))
counting_function(data)
counting_function(data[data$D1,])
counting_function(data[data$D2,])
counting_function(data[data$D3,])

# table 2
colnames(data)

# fig. 2
outcome_function("D2", data$TypePhaseName %in%  regulation)
outcome_function("D2", data$TypePhaseName %in%  extra_time)
outcome_function("D2", data$TypePhaseName ==  "Penalty Shoot-Out")

outcome_function("D3", data$TypePhaseName %in%  regulation)
outcome_function("D3", data$TypePhaseName %in%  extra_time)
outcome_function("D3", data$TypePhaseName ==  "Penalty Shoot-Out")

# table 3
outcome_function("D3", data$TypePhaseName %in%  in_game & data$CompetitionShortName == "cups")
outcome_function("D3", data$TypePhaseName %in%  in_game & data$CompetitionShortName == "int")
outcome_function("D3", data$TypePhaseName %in%  in_game & data$CompetitionShortName == "nat")
outcome_function("D3", data$TypePhaseName %in%  in_game & data$CompetitionShortName %in% c("cups","int","nat"))

outcome_function("D3", data$TypePhaseName == "Penalty Shoot-Out" & data$CompetitionShortName == "cups")
outcome_function("D3", data$TypePhaseName == "Penalty Shoot-Out" & data$CompetitionShortName == "int")
outcome_function("D3", data$TypePhaseName == "Penalty Shoot-Out" & data$CompetitionShortName == "nat")
outcome_function("D3", data$TypePhaseName == "Penalty Shoot-Out" & data$CompetitionShortName %in% c("cups","int","nat"))

#### 3.  Results ####

counting_function(data[data$D2,])["shootout"] / counting_function(data[data$D2,])["penalties"]
counting_function(data[data$D3,])["shootout"] / counting_function(data[data$D3,])["penalties"]

counting_function(data[data$D2 & data$homeTeamName == data$PenaltyTakerTeamName,])["in.game"] / counting_function(data[data$D2,])["in.game"]
counting_function(data[data$D2 & data$awayTeamName == data$PenaltyTakerTeamName,])["in.game"] / counting_function(data[data$D2,])["in.game"]

counting_function(data[data$D3 & data$homeTeamName == data$PenaltyTakerTeamName,])["in.game"] / counting_function(data[data$D3,])["in.game"]
counting_function(data[data$D3 & data$awayTeamName == data$PenaltyTakerTeamName,])["in.game"] / counting_function(data[data$D3,])["in.game"]

colSums(is.na(data[data$D3,]))
colSums(is.na(data[data$D2,]))

length(unique(data[data$D2,"player_name"]))
length(unique(data[data$D3,"player_name"]))

length(unique(data[data$D2,"goalie_name"]))
length(unique(data[data$D3,"goalie_name"]))


#### 3.1  Outcomes by penalty condition #### 

# table 4
big5_leagues <- c("leagues/es1-laliga","leagues/fr1-ligue-1","leagues/gb1-premier-league","leagues/l1-bundesliga","leagues/it1-serie-a")

length(unique(data[data$D2 & data$CompetitionShortName == "leag","TournamentName" ]))
outcome_function("D2", data$TournamentName %in%  big5_leagues)
outcome_function("D2", (!data$TournamentName %in%  big5_leagues) & data$CompetitionShortName == "leag")
outcome_function("D2", data$CompetitionShortName == "leag")

length(unique(data[data$D3 & data$CompetitionShortName == "leag","TournamentName" ]))
outcome_function("D3", data$TournamentName %in%  big5_leagues)
outcome_function("D3", (!data$TournamentName %in%  big5_leagues) & data$CompetitionShortName == "leag")
outcome_function("D3", data$CompetitionShortName == "leag")

# fig 3
players_shootout_names <- unique(data[data$D3 & data$TypePhaseName == "Penalty Shoot-Out", "player_name"])
players_ingame_names <- unique(data[data$D3 & data$TypePhaseName %in% in_game, "player_name"])
players_shootout_only <- players_shootout_names[!players_shootout_names %in% players_ingame_names]
players_ingame_only <- players_ingame_names[!players_ingame_names %in% players_shootout_names]
players_both <- players_shootout_names[players_shootout_names %in% players_ingame_names]
length(players_both)

outcome_function("D3", data$player_name %in% players_ingame_only)
outcome_function("D3", data$player_name %in% players_both & data$TypePhaseName %in% in_game)
outcome_function("D3", data$player_name %in% players_both & data$TypePhaseName == "Penalty Shoot-Out")
outcome_function("D3", data$player_name %in% players_shootout_only)

# table 5: log reg

# define variables
players_shootout_names_D2 <- unique(data[data$D2 & data$TypePhaseName == "Penalty Shoot-Out", "player_name"])
players_ingame_names_D2 <- unique(data[data$D2 & data$TypePhaseName %in% in_game, "player_name"])
players_shootout_only_D2 <- players_shootout_names_D2[!players_shootout_names_D2 %in% players_ingame_names_D2]
players_ingame_only_D2 <- players_ingame_names_D2[!players_ingame_names_D2 %in% players_shootout_names_D2]
players_both_D2 <- players_shootout_names_D2[players_shootout_names_D2 %in% players_ingame_names_D2]
players_experienced_D2 <- names(table(data[data$D2 & data$player_name %in% players_both_D2, "player_name"])[table(data[data$D2 & data$player_name %in% players_both_D2, "player_name"]) > 2])

#fit regression
glm_fit <- glm(EventTypeName== "Goal" ~ I(TypePhaseName == "Penalty Shoot-Out") +
		I(player_name %in% players_experienced_D2) +
		I(player_name %in% players_ingame_only_D2) +
		I(player_name %in% players_shootout_only_D2) +
		I(CompetitionShortName == "cups") +
		I(CompetitionShortName == "int") +
		I(CompetitionShortName == "nat") +
		I(homeTeamName == PenaltyTakerTeamName) +
		SeasonID,
		data=data[data$D2,], family = "binomial")
summary_logreg <- summary(glm_fit)
summary_logreg

output_reg <- data.frame(summary_logreg$coefficients)
p.adjust(output_reg[,"Pr...z.."], method = "holm")


#### 3.2.1 Penalty takers #### 

# Fig 4
g <- 1
while (sum(table(data[data$D2,]$player_name)>=g) >= 50){g <-g+1}
n_player <- g-1

players_50 <- names(table(data[data$D2,]$player_name)[table(data[data$D2,]$player_name)>=n_player])
players_50_stats <- data.frame(matrix(NA,ncol=2,nrow = length(players_50)))
colnames(players_50_stats) <- c("penalties","goal")
rownames(players_50_stats) <- str_to_title(players_50)

for (i in 1:length(players_50)){
	players_50_stats[i,c("penalties","goal")] <- outcome_function("D2", data$player_name %in% players_50[i])
}

players_50_stats <- players_50_stats[order(players_50_stats[,"goal"],decreasing = T),]
nrow(players_50_stats)

outcome_function("D2", data$player_name %in% players_50)
outcome_function("D2", !data$player_name %in% players_50)
outcome_function("D2")

outcome_function("D2", data$player_name == "Max Kruse")
outcome_function("D2", data$player_name == "Cristiano Ronaldo")
outcome_function("D2", data$player_name == "Lionel Messi")
outcome_function("D2", data$player_name == "Dani Parejo")

sort(table(data[data$D2 & data$TypePhaseName == "Penalty Shoot-Out","player_name"]), decreasing=T)[1:10]


##### 3.2.2 Goalkeepers ##### 

# Fig 5
cond_ingame_d3 <- data$D3 & data$TypePhaseName != "Penalty Shoot-Out"
g <- 1
while (sum(table(data[cond_ingame_d3,]$goalie_name)>=g) >= 50){g <-g+1}
n_player <- g-1

players_50 <- names(table(data[cond_ingame_d3,]$goalie_name)[table(data[cond_ingame_d3,]$goalie_name)>=n_player])
players_50_stats <- data.frame(matrix(NA,ncol=4,nrow = length(players_50)))
colnames(players_50_stats) <- c("penalties","goal", "save", "miss")
rownames(players_50_stats) <- str_to_title(players_50)

for (i in 1:length(players_50)){
	players_50_stats[i,c("penalties","goal", "save", "miss")] <- outcome_function("D3", cond_ingame_d3 & data$goalie_name %in% players_50[i])
}

players_50_stats <- players_50_stats[order(players_50_stats[,"save"],decreasing = T),]
nrow(players_50_stats)

cor.test(players_50_stats[,"save"],players_50_stats[,"miss"], method = "pearson")

outcome_function("D3", cond_ingame_d3 & data$goalie_name %in% players_50)
outcome_function("D3", cond_ingame_d3 & !(data$goalie_name %in% players_50))

sort(table(data[data$D3 & data$TypePhaseName != "Penalty Shoot-Out","goalie_name"]), decreasing=T)[1:10]
outcome_function("D3", cond_ingame_d3 & data$goalie_name == "Alban Lafont")

# Fig 6
cond_shoot_d3 <- data$D3 & data$TypePhaseName == "Penalty Shoot-Out"
g <- 1
while (sum(table(data[cond_shoot_d3,]$goalie_name)>=g) >= 50){g <-g+1}
n_player <- g-1

players_50 <- names(table(data[cond_shoot_d3,]$goalie_name)[table(data[cond_shoot_d3,]$goalie_name)>=n_player])
players_50_stats <- data.frame(matrix(NA,ncol=4,nrow = length(players_50)))
colnames(players_50_stats) <- c("penalties","goal", "save", "miss")
rownames(players_50_stats) <- str_to_title(players_50)

for (i in 1:length(players_50)){
	players_50_stats[i,c("penalties","goal", "save", "miss")] <- outcome_function("D3", cond_shoot_d3 & data$goalie_name %in% players_50[i])
}

players_50_stats <- players_50_stats[order(players_50_stats[,"save"],decreasing = T),]
nrow(players_50_stats)

outcome_function("D3", cond_shoot_d3 & data$goalie_name == "Leandro Chichizola")
outcome_function("D3", cond_shoot_d3 & data$goalie_name == "Anton Sytnykov")
outcome_function("D3", cond_ingame_d3 & data$goalie_name == "David de Gea")

data[data$D3 & data$OfficialMatchName =="Villarreal CF - Manchester United",]
data[9432,]


#### 3.2.3 Teams taking penalties #### 

# Fig 7
cond_ingame_d3 <- data$D3 & data$TypePhaseName != "Penalty Shoot-Out"
g <- 1
while (sum(table(data[cond_ingame_d3,]$PenaltyTakerTeamName)>=g) >= 50){g <-g+1}
n_player <- g-1

players_50 <- names(table(data[cond_ingame_d3,]$PenaltyTakerTeamName)[table(data[cond_ingame_d3,]$PenaltyTakerTeamName)>=n_player])
players_50_stats <- data.frame(matrix(NA,ncol=4,nrow = length(players_50)))
colnames(players_50_stats) <- c("penalties","goal", "save", "miss")
rownames(players_50_stats) <- str_to_title(players_50)

for (i in 1:length(players_50)){
	players_50_stats[i,c("penalties","goal", "save", "miss")] <- outcome_function("D3", cond_ingame_d3 & data$PenaltyTakerTeamName %in% players_50[i])
}

players_50_stats <- players_50_stats[order(players_50_stats[,"goal"],decreasing = T),]
nrow(players_50_stats)

outcome_function("D3", cond_ingame_d3 & data$PenaltyTakerTeamName %in% players_50)
outcome_function("D3", cond_ingame_d3 & !data$PenaltyTakerTeamName %in% players_50)

# Fig 8
cond_shoot_d3 <- data$D3 & data$TypePhaseName == "Penalty Shoot-Out"
g <- 1
while (sum(table(data[cond_shoot_d3,]$PenaltyTakerTeamName)>=g) >= 50){g <-g+1}
n_player <- g-1

players_50 <- names(table(data[cond_shoot_d3,]$PenaltyTakerTeamName)[table(data[cond_shoot_d3,]$PenaltyTakerTeamName)>=n_player])
players_50_stats <- data.frame(matrix(NA,ncol=4,nrow = length(players_50)))
colnames(players_50_stats) <- c("penalties","goal", "save", "miss")
rownames(players_50_stats) <- str_to_title(players_50)

for (i in 1:length(players_50)){
	players_50_stats[i,c("penalties","goal", "save", "miss")] <- outcome_function("D3", cond_shoot_d3 & data$PenaltyTakerTeamName %in% players_50[i])
}

players_50_stats <- players_50_stats[order(players_50_stats[,"goal"],decreasing = T),]
nrow(players_50_stats)

sort(table(data[data$D3 & data$TypePhaseName == "Penalty Shoot-Out","PenaltyTakerTeamName"]), decreasing=T)[1:10]


#### 3.3 Outcomes by moments in time ####
#### 3.3.1 In-game penalties: match time #### 

## Fig 9

## no of penalties regular 90min ##
sum(data$D3 & data$TypePhaseName %in% regulation)
sum(data$D3 & data$TypePhaseName %in% "First half")
sum(data$D3 & data$TypePhaseName %in% "First half")/sum(data$D3 & data$TypePhaseName %in% regulation) *100
sum(data$D3 & data$TypePhaseName %in% "Second half")
sum(data$D3 & data$TypePhaseName %in% "Second half")/sum(data$D3 & data$TypePhaseName %in% regulation) *100

data_regular_fatigue <- data[data$D3 & !is.na(data$PenaltyMinute),]
sum(is.na(data$PenaltyMinute)) # delete 84 where time is missing

outcome_function("D3", data$TypePhaseName %in% "First half")
outcome_function("D3", data$TypePhaseName %in% "Second half")

data_first_half <- data_regular_fatigue[data_regular_fatigue$TypePhaseName == "First half",] 
data_second_half <- data_regular_fatigue[data_regular_fatigue$TypePhaseName == "Second half",] 

## first half
data_first_pen_time <- data.frame(matrix(t(table(data_first_half$EventTypeName, data_first_half$PenaltyMinute)),ncol=3))
colnames(data_first_pen_time) <- colnames(t(table(data_first_half$EventTypeName, data_first_half$PenaltyMinute)))
rownames(data_first_pen_time) <- rownames(t(table(data_first_half$EventTypeName, data_first_half$PenaltyMinute)))
data_first_pen_time <- data_first_pen_time[order(as.numeric(gsub("'", "", rownames(data_first_pen_time)))),]
data_first_pen_time[,"penalties"] <- rowSums(data_first_pen_time)
data_first_pen_time[,"PenaltyMinute"] <- as.numeric(gsub("'", "", rownames(data_first_pen_time)))

## second half
data_second_pen_time <- data.frame(matrix(t(table(data_second_half$EventTypeName, data_second_half$PenaltyMinute)),ncol=3))
colnames(data_second_pen_time) <- colnames(t(table(data_second_half$EventTypeName, data_second_half$PenaltyMinute)))
rownames(data_second_pen_time) <- rownames(t(table(data_second_half$EventTypeName, data_second_half$PenaltyMinute)))
data_second_pen_time <- data_second_pen_time[order(as.numeric(gsub("'", "", rownames(data_second_pen_time)))),]
data_second_pen_time[,"penalties"] <- rowSums(data_second_pen_time)
data_second_pen_time[,"PenaltyMinute"] <- as.numeric(gsub("'", "", rownames(data_second_pen_time)))

## loess fit for added time 
loess_first_half <- loess(penalties ~ PenaltyMinute, data = data_first_pen_time[1:44,], control=loess.control(surface="direct"))
expected_45 <- predict(loess_first_half, newdata = data.frame("PenaltyMinute"=45))

loess_second_half <- loess(penalties ~ PenaltyMinute, data = data_second_pen_time[1:44,], control=loess.control(surface="direct"))
expected_90 <- predict(loess_second_half, newdata = data.frame("PenaltyMinute"=90))

ratio_in_46 <- (data_first_pen_time["45","penalties"]-expected_45)/data_first_pen_time["45","penalties"]
data_first_pen_time["46",] <- c(ratio_in_46* data_first_pen_time["45",c("Goal", "Missed", "Save" ,"penalties")],46)
data_first_pen_time["45",] <- c((1-ratio_in_46)* data_first_pen_time["45",c("Goal", "Missed", "Save" ,"penalties")],45)

round(data_first_pen_time["46","penalties"]/data_first_pen_time["45","penalties"])
data_first_pen_time["47",] <- c(1/3* data_first_pen_time["46",c("Goal", "Missed", "Save" ,"penalties")],47)
data_first_pen_time["48",] <- c(1/3* data_first_pen_time["46",c("Goal", "Missed", "Save" ,"penalties")],48)
data_first_pen_time["46",] <- c(1/3* data_first_pen_time["46",c("Goal", "Missed", "Save" ,"penalties")],46)

ratio_in_91 <- (data_second_pen_time["90","penalties"]-expected_90)/data_second_pen_time["90","penalties"]
data_second_pen_time["91",] <- c(ratio_in_91* data_second_pen_time["90",c("Goal", "Missed", "Save" ,"penalties")],91)
data_second_pen_time["90",] <- c((1-ratio_in_91)* data_second_pen_time["90",c("Goal", "Missed", "Save" ,"penalties")],90)

round(data_second_pen_time["91","penalties"]/data_second_pen_time["90","penalties"])

data_second_pen_time["92",] <- c(1/5* data_second_pen_time["91",c("Goal", "Missed", "Save" ,"penalties")],92)
data_second_pen_time["93",] <- c(1/5* data_second_pen_time["91",c("Goal", "Missed", "Save" ,"penalties")],93)
data_second_pen_time["94",] <- c(1/5* data_second_pen_time["91",c("Goal", "Missed", "Save" ,"penalties")],94)
data_second_pen_time["95",] <- c(1/5* data_second_pen_time["91",c("Goal", "Missed", "Save" ,"penalties")],95)
data_second_pen_time["91",] <- c(1/5* data_second_pen_time["91",c("Goal", "Missed", "Save" ,"penalties")],91)

data_first_roll <- data.frame(apply(data_first_pen_time[,c("Goal","Missed","Save")],2,rollsum, k=5,fill=NA))
data_first_rel <- data.frame(t(apply(data_first_roll[,c("Goal","Missed","Save")],1,function(x){x/sum(x)}))*100)

data_second_roll <- data.frame(apply(data_second_pen_time[,c("Goal","Missed","Save")],2,rollsum, k=5,fill=NA))
data_second_rel <- data.frame(t(apply(data_second_roll[,c("Goal","Missed","Save")],1,function(x){x/sum(x)}))*100)

data_first_rel[,"penalties"] <- data_first_pen_time$penalties
data_second_rel[,"penalties"] <- data_second_pen_time$penalties

# extra time 
data_regular_120_D2.3 <- data[data$D3 & data$TypePhaseName %in% extra_time,]

data_extra_pen_time <- matrix(table(data_regular_120_D2.3$PenaltyMinute,data_regular_120_D2.3$EventTypeName ),ncol=3)
rownames(data_extra_pen_time) <-rownames(table(data_regular_120_D2.3$PenaltyMinute,data_regular_120_D2.3$EventTypeName ))
colnames(data_extra_pen_time) <-colnames(table(data_regular_120_D2.3$PenaltyMinute,data_regular_120_D2.3$EventTypeName ))
data_extra_pen_time <- data.frame(data_extra_pen_time[order(as.numeric(gsub("'", "", rownames(data_extra_pen_time)))),])
data_extra_pen_time[,"penalties"] <- rowSums(data_extra_pen_time)
data_extra_pen_time[,"PenaltyMinute"] <- as.numeric(gsub("'", "", rownames(data_extra_pen_time)))

# normalization for extra time

norm_extra_time <- 26.8824041811847 # ratio of matches without and with extra time
data_extra_pen_time[,"penalties"] <- data_extra_pen_time[,"penalties"] * norm_extra_time

loess_first_extra <- loess(penalties ~ PenaltyMinute, data = data_extra_pen_time[1:14,], control=loess.control(surface="direct"))
expected_105 <- predict(loess_first_extra, newdata = data.frame("PenaltyMinute"=105))
data_extra_pen_time["105'","penalties"] <- expected_105

# (data_extra_pen_time["105","penalties"] - expected_105) / expected_105

loess_second_extra <- loess(penalties ~ PenaltyMinute, data = data_extra_pen_time[16:29,], control=loess.control(surface="direct"))
expected_120 <- predict(loess_second_extra, newdata = data.frame("PenaltyMinute"=120))
data_extra_pen_time["120'","penalties"] <- expected_120

data_extra_roll_first <- data.frame(apply(data_extra_pen_time[1:15,c("Goal","Missed","Save")],2,rollsum, k=5,fill=NA))
data_extra_roll_second <- data.frame(apply(data_extra_pen_time[16:30,c("Goal","Missed","Save")],2,rollsum, k=5,fill=NA))
data_extra_roll <- rbind(data_extra_roll_first,data_extra_roll_second)
data_extra_rel <- data.frame(t(apply(data_extra_roll[,c("Goal","Missed","Save")],1,function(x){x/sum(x)}))*100)
data_extra_rel[,"penalties"] <- data_extra_pen_time$penalties

# rbind all phases 
data_rel_all <- rbind(data_first_rel,data_second_rel,data_extra_rel)
data_rel_all

#### 3.3.2 Shoot-out penalties: alternating order #### 

data_shootout_D2.2 <- data[data$D2 & data$TypePhaseName == "Penalty Shoot-Out",]

nrow(data_shootout_D2.2)
length(unique(data_shootout_D2.2$fcompMatchID))

taker_score_shoot = matrix(NA,nrow = nrow(data_shootout_D2.2),ncol = 1)
goalie_score_shoot = matrix(NA,nrow = nrow(data_shootout_D2.2),ncol = 1)

for (i in 1:nrow(data_shootout_D2.2)){
	
	score = str_extract_all(data_shootout_D2.2$ScoreBefore[i],"\\d+")
	
	score_home = as.numeric(score[[1]][1])
	score_away = as.numeric(score[[1]][2])
	
	team_taker = data_shootout_D2.2$PenaltyTakerTeamName[i]
	team_home = data_shootout_D2.2$homeTeamName[i]
	team_away = data_shootout_D2.2$awayTeamName[i]
	
	if (team_taker == team_home){
		
		taker_score_shoot[i] = score_home
		goalie_score_shoot[i] = score_away
	}
	
	if (team_taker == team_away){
		goalie_score_shoot[i] = score_home
		taker_score_shoot[i] = score_away
	}
	
}

data_shootout_D2.2[,"taker_score"] <- taker_score_shoot
data_shootout_D2.2[,"goalie_score"] <- goalie_score_shoot

data_shoot_time <- table(data_shootout_D2.2$order,data_shootout_D2.2$EventTypeName)
shootout_mean_order <- data_shoot_time/apply(data_shoot_time,1,sum)
shootout_mean_order <- cbind(shootout_mean_order,"size"=apply(data_shoot_time,1,sum))

shootout_mean_order <- data.frame(shootout_mean_order[,c("Goal","size")])
shootout_mean_order[,"order"] <- rownames(shootout_mean_order)
shootout_mean_order$Goal <- round(shootout_mean_order$Goal*100,2)
colnames(shootout_mean_order) <- c("goal","penalties","order")

# table 6: Potential Last Penalty #

data_shoot_gametime <- data_shootout_D2.2
for (i in 1:nrow(data_shoot_gametime)){
	
	taker_diff <- data_shoot_gametime[i,"taker_score"] - data_shoot_gametime[i,"goalie_score"]
	
	# 1. if no condition is fulfilled
	data_shoot_gametime[i,"pressure"] <- "no"
	
	# 2. 6th penalty
	if (data_shoot_gametime[i,"order"] == 6){
		
		if (data_shoot_gametime[i,"taker_score"] == 2 & data_shoot_gametime[i,"goalie_score"] == 0){
			data_shoot_gametime[i,"pressure"] <- "win"
		}
		
		if (data_shoot_gametime[i,"taker_score"] == 0 & data_shoot_gametime[i,"goalie_score"] == 3){
			data_shoot_gametime[i,"pressure"] <- "lose"
		}
	}
	
	# 3. 7th penalty
	if (data_shoot_gametime[i,"order"] == 7){
		
		if (taker_diff == 2){
			data_shoot_gametime[i,"pressure"] <- "win"
		}
		
		if (taker_diff == -2){
			data_shoot_gametime[i,"pressure"] <- "lose"
		}
	}
	
	# 4. 8th penalty
	if (data_shoot_gametime[i,"order"] == 8){
		
		if (taker_diff == 1){
			data_shoot_gametime[i,"pressure"] <- "win"
		}
		
		if (taker_diff == -2){
			data_shoot_gametime[i,"pressure"] <- "lose"
		}
	}
	
	# 5. 9th penalty
	if (data_shoot_gametime[i,"order"] == 9){
		
		if (taker_diff == 1){
			data_shoot_gametime[i,"pressure"] <- "win"
		}
		
		if (taker_diff == -1){
			data_shoot_gametime[i,"pressure"] <- "lose"
		}
	}
	# 6. > 9th penalty
	if (data_shoot_gametime[i,"order"] >=10 & data_shoot_gametime[i,"order"]%%2 ==0){
		
		if (taker_diff == 0){
			data_shoot_gametime[i,"pressure"] <- "win"
		}
		
		if (taker_diff == -1){
			data_shoot_gametime[i,"pressure"] <- "lose"
		}
	}
}

table(data_shoot_gametime$pressure)
mean(data_shoot_gametime[data_shoot_gametime$pressure=="win","EventTypeName"] == "Goal")
mean(data_shoot_gametime[data_shoot_gametime$pressure=="lose","EventTypeName"] == "Goal")
mean(data_shoot_gametime[data_shoot_gametime$pressure=="no","EventTypeName"] == "Goal")


# who won more games ?
matches_shootout_all <- unique(data_shootout_D2.2$fcompMatchID)

data_shoot_winner <- matrix(NA,ncol=9, nrow=length(matches_shootout_all))
colnames(data_shoot_winner) <- c("beginner","winner","home","away","name","shortname","fcompMatchID", "n_pen","goal")
last_pen <- matrix(NA,ncol=1, nrow=length(matches_shootout_all))
last_pen_res <- matrix(NA,ncol=1, nrow=length(matches_shootout_all))
goalies_both <- matrix(NA,ncol=2, nrow=length(matches_shootout_all))
last_pen_id <- list()

for (i in 1:length(matches_shootout_all)){
	set <- data_shootout_D2.2[data_shootout_D2.2$fcompMatchID==matches_shootout_all[i],]
	id_first <- set$order==1
	data_shoot_winner[i,"beginner"] <- set[id_first,"PenaltyTakerTeamName"]
	data_shoot_winner[i,"home"] <- set[id_first,"homeTeamName"]
	data_shoot_winner[i,"away"] <- set[id_first,"awayTeamName"]
	data_shoot_winner[i,"name"] <- set[id_first,"CompetitionName"]
	data_shoot_winner[i,"shortname"] <- set[id_first,"CompetitionShortName"]
	data_shoot_winner[i,"fcompMatchID"] <- set[id_first,"fcompMatchID"]
	data_shoot_winner[i,"n_pen"] <- max(set$order)
	data_shoot_winner[i,"goal"] <- set[max(set$order),"EventTypeName"]
	
	score <- as.numeric(str_extract_all(set[set$order==max(set$order),"ScoreAfter"],"\\d+", simplify = T))
	
	if (score[1] > score[2]){
		data_shoot_winner[i,"winner"] <- set[id_first,"homeTeamName"]
	}
	if (score[2] > score[1]){
		data_shoot_winner[i,"winner"] <- set[id_first,"awayTeamName"]
	}
	if (max(set$order) <=5){ # not possible
		data_shoot_winner[i,"winner"] <- NA
	}
	
	if (score[2] == score[1]){ # not possible
		data_shoot_winner[i,"winner"] <- NA
	}
	
	last_pen[i,1] <- max(set$order)
	last_pen_res[i,1] <- toString(set[set$order == max(set$order),"EventTypeName"])
	goalies_both[i,1:2] <- set[set$order %in% 1:2,"goalie_name"]
	
	last_pen_id[[i]] <- set$order == max(set$order)
	
}


data_shoot_winner <- data.frame(data_shoot_winner)
nrow(data_shoot_winner)
mean(data_shoot_winner$beginner==data_shoot_winner$winner)

mean(data_shoot_winner$winner==data_shoot_winner$home)
mean(data_shoot_winner$winner==data_shoot_winner$away)

median(as.numeric(data_shoot_winner$n_pen))
mean(as.numeric(data_shoot_winner$n_pen) > 10)
sum(as.numeric(data_shoot_winner$n_pen) > 18)

data_shoot_winner[data_shoot_winner$n_pen == 32,]

players_first2 <- data_shootout_D2.2[data_shootout_D2.2$order %in% c(1:2), "player_name"]
outcome_function("D2", data$TypePhaseName %in% in_game & data$player_name %in% players_first2)

data_last <- data_shoot_gametime[unlist(last_pen_id)==T,]
data_not_last <- data_shoot_gametime[unlist(last_pen_id)==F,]
mean(data_last$EventTypeName== "Goal")
nrow(data_last)
mean(data_not_last$EventTypeName== "Goal")
nrow(data_not_last)

# outlier 3 result #
data_outlier_3 <- data_shootout_D2.2[data_shootout_D2.2$order==3,]
n_data_outlier_3 <- table(data_outlier_3$ScoreBefore)
names_3 <- names(n_data_outlier_3)
data_out_outlier3 <- matrix(NA,nrow = 2, ncol = length(names_3))
colnames(data_out_outlier3) <- names_3
rownames(data_out_outlier3) <- c("n","goal")
data_out_outlier3["n",]<-n_data_outlier_3

for (i in 1:length(names_3)){
	
	data_outlier_3_res <- data_outlier_3[data_outlier_3$ScoreBefore == names_3[i],]
	data_out_outlier3["goal",names_3[i]] <- mean(data_outlier_3_res$EventTypeName=="Goal")
}
data_out_outlier3

# fig 10 

# we'll be incrementing a lot
inc <- function(x,y) { eval.parent(substitute(x <- x+y)) }

# goal probabilities for teams A and B by in shooting order
fig10_data <- data_shoot_time/apply(data_shoot_time,1,sum)
fig10_data_18 <- fig10_data[1:18,1]

A<- fig10_data_18[seq(1,17,2)]
B<- fig10_data_18[seq(2,18,2)]

# P: 1+penalty number by goal difference A-B+4 (1:-3, 4:0, 7:+3 for A)
P <- array(0,dim=c(19,7))
# score is level before first penalty with probability 1
P[1,4] <- 1 

# first 2*3 penalties are always taken
for(i in 1:3) {
	# Ai: max diff is -2 to +2
	for(j in 2:6)
	{
		inc(P[2*i  ,j  ], (1-A[i])*P[2*i-1,j])
		inc(P[2*i  ,j+1],    A[i] *P[2*i-1,j])
	}
	# Bi: A may be at +3 (j=7) after A3
	for(j in 2:7) 
	{
		inc(P[2*i+1,j  ], (1-B[i])*P[2*i  ,j])
		inc(P[2*i+1,j-1],    B[i] *P[2*i  ,j])
	}
}

# A4: A already lost if diff=-3, won if diff=3
for(j in 2:6)
{
	inc(P[8,j]  , (1-A[4])*P[7,j])
	inc(P[8,j+1],    A[4] *P[7,j])
}
# B4: B won if diff=-3,-2, lost if diff=3
for(j in 3:6)
{
	inc(P[9,j]  , (1-B[4])*P[8,j])
	inc(P[9,j-1],    B[4] *P[8,j])
}

# A5: A shoot only if diff=-1,0,+1
for(j in 3:5)
{
	inc(P[10,j]  , (1-A[5])*P[ 9,j])
	inc(P[10,j+1],    A[5] *P[ 9,j])
}
# B5: B shoot only if diff=0,+1
for(j in 4:5)
{
	inc(P[11,j]  , (1-B[5])*P[10,j])
	inc(P[11,j-1],    B[5] *P[10,j])
}

# A6-B9
for(i in 6:length(A)) {
	# Ai (score must be level)
	inc(P[2*i,4]  , (1-A[i])*P[2*i-1,4])
	inc(P[2*i,4+1],    A[i] *P[2*i-1,4])
	# Bi (level or A up by one)
	for(j in 4:5)
	{
		inc(P[2*i+1,j]  , (1-B[i])*P[2*i,j])
		inc(P[2*i+1,j-1],    B[i] *P[2*i,j])
	}
}

# A or B win if j (=diff+4) has the following value
WA <- c(0,0,0,0,0,7, 7,6, 6,5, 0,5,0,5,0,5,0,5)
WB <- c(0,0,0,0,0,1, 2,2, 3,3, 0,3,0,3,0,3,0,3)
W <- array(0,dim=c(18,2))
# from sixth to tenth penalty, each may decide
for(i in 6:10) {
	W[i,1] <- P[1+i,WA[i]]
	W[i,2] <- P[1+i,WB[i]]
}
# after that, only even penalties can decide (12th to 18th)
for(i in 6:9) {
	W[2*i,1] <- P[1+2*i,WA[2*i]]
	W[2*i,2] <- P[1+2*i,WB[2*i]]
}

cumsum(W[,1])
cumsum(W[,2])

table(data_shoot_winner[data_shoot_winner$goal=="Goal","n_pen"]) / nrow(data_shoot_winner)

# table 7
data_score_analysis <- data[data$D3 & data$TypePhaseName %in% in_game ,]
sum(is.na(data_score_analysis$ScoreAfter))
data_score_analysis <- data_score_analysis[! is.na(data_score_analysis$ScoreAfter),]

data_score_split <- data.frame(str_split(data_score_analysis$ScoreBefore,pattern = ":",simplify = T))
home_id <- data_score_analysis$homeTeamName == data_score_analysis$PenaltyTakerTeamName
away_id <- data_score_analysis$awayTeamName == data_score_analysis$PenaltyTakerTeamName

data_score_analysis[home_id,"score_taker_team"] <- data_score_split[home_id,1]
data_score_analysis[away_id,"score_taker_team"] <- data_score_split[away_id,2]

data_score_analysis[home_id,"score_goalie_team"] <- data_score_split[home_id,2]
data_score_analysis[away_id,"score_goalie_team"] <- data_score_split[away_id,1]

data_score_leading <- data_score_analysis[data_score_analysis$score_taker_team > data_score_analysis$score_goalie_team,]
data_score_draw <- data_score_analysis[data_score_analysis$score_taker_team == data_score_analysis$score_goalie_team,]
data_score_behind <- data_score_analysis[data_score_analysis$score_taker_team < data_score_analysis$score_goalie_team,]

table(data_score_leading$EventTypeName) / sum(table(data_score_leading$EventTypeName)) *100
table(data_score_draw$EventTypeName) / sum(table(data_score_draw$EventTypeName))*100
table(data_score_behind$EventTypeName) / sum(table(data_score_behind$EventTypeName))*100

nrow(data_score_leading)
nrow(data_score_draw)
nrow(data_score_behind)


#### 4.3 There is no first-mover advantage ####

nrow(data_shoot_winner)
mean(data_shoot_winner$beginner == data_shoot_winner$winner) *100

top_cups <- c("cups/cdr-copa-del-rey","cups/frc-coupe-de-france","cups/fac-fa-cup","cups/cgb-efl-cup","cups/dfb-dfb-pokal","cups/cit-coppa-italia")

#fma per tournament
top_cups <- c("cups/cdr-copa-del-rey","cups/frc-coupe-de-france","cups/fac-fa-cup","cups/cgb-efl-cup","cups/dfb-dfb-pokal","cups/cit-coppa-italia")

data_shoot_winner$shortname[data_shoot_winner$shortname=="cups"] <- substr(data_shoot_winner$name,1,nchar(data_shoot_winner$name)-12)[data_shoot_winner$shortname=="cups"]

data_shoot_winner[,"fma"] <- data_shoot_winner$beginner==data_shoot_winner$winner
data_fma_tournament <- table(data_shoot_winner$shortname,data_shoot_winner$fma)

fma_per_ter <- matrix(data_fma_tournament[,2]/ (data_fma_tournament[,1]+data_fma_tournament[,2]))
rownames(fma_per_ter) <- rownames(data_fma_tournament)
data_fma_final <- data.frame(fma_per_ter)
data_fma_final[,"n"] <- (data_fma_tournament[,1]+data_fma_tournament[,2])
data_fma_final <- data_fma_final[order(data_fma_final$fma_per_ter, decreasing = T),]
data_fma_final_top <- data_fma_final[rownames(data_fma_final) %in% top_cups,]
round(sum(data_fma_final_top[,1]*data_fma_final_top[,2])/sum(data_fma_final_top[,2])*100,2)
sum(data_fma_final_top[,2])




 