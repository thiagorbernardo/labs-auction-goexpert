package auction

import (
	"context"
	"fmt"
	"fullcycle-auction_go/configuration/logger"
	"fullcycle-auction_go/internal/entity/auction_entity"
	"fullcycle-auction_go/internal/internal_error"
	"os"
	"sync"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type AuctionEntityMongo struct {
	Id          string                          `bson:"_id"`
	ProductName string                          `bson:"product_name"`
	Category    string                          `bson:"category"`
	Description string                          `bson:"description"`
	Condition   auction_entity.ProductCondition `bson:"condition"`
	Status      auction_entity.AuctionStatus    `bson:"status"`
	Timestamp   int64                           `bson:"timestamp"`
}
type AuctionRepository struct {
	Collection *mongo.Collection
	mutex      *sync.Mutex
}

func NewAuctionRepository(database *mongo.Database) *AuctionRepository {
	return &AuctionRepository{
		Collection: database.Collection("auctions"),
		mutex:      &sync.Mutex{},
	}
}

func (ar *AuctionRepository) CreateAuction(
	ctx context.Context,
	auctionEntity *auction_entity.Auction) *internal_error.InternalError {
	auctionEntityMongo := &AuctionEntityMongo{
		Id:          auctionEntity.Id,
		ProductName: auctionEntity.ProductName,
		Category:    auctionEntity.Category,
		Description: auctionEntity.Description,
		Condition:   auctionEntity.Condition,
		Status:      auctionEntity.Status,
		Timestamp:   auctionEntity.Timestamp.Unix(),
	}
	_, err := ar.Collection.InsertOne(ctx, auctionEntityMongo)
	if err != nil {
		logger.Error("Error trying to insert auction", err)
		return internal_error.NewInternalServerError("Error trying to insert auction")
	}

	return nil
}

// CloseExpiredAuctions closes all auctions that have exceeded their time limit
func (ar *AuctionRepository) CloseExpiredAuctions(
	ctx context.Context,
	auctionInterval time.Duration) *internal_error.InternalError {

	ar.mutex.Lock()
	defer ar.mutex.Unlock()

	// Calculate the cutoff time - auctions created before this time should be closed
	cutoffTime := time.Now().Add(-auctionInterval).Unix()

	// Find all active auctions that have expired
	filter := bson.M{
		"status":    auction_entity.Active,
		"timestamp": bson.M{"$lt": cutoffTime},
	}

	// Update expired auctions to Completed status
	update := bson.M{
		"$set": bson.M{
			"status": auction_entity.Completed,
		},
	}

	result, err := ar.Collection.UpdateMany(ctx, filter, update)
	if err != nil {
		logger.Error("Error trying to close expired auctions", err)
		return internal_error.NewInternalServerError("Error trying to close expired auctions")
	}

	if result.ModifiedCount > 0 {
		logger.Info(fmt.Sprintf("Closed %d expired auctions", result.ModifiedCount))
	}

	return nil
}

// StartAuctionCloseRoutine starts a goroutine that periodically closes expired auctions
func (ar *AuctionRepository) StartAuctionCloseRoutine(ctx context.Context) {
	checkInterval := getAuctionCheckInterval()
	auctionInterval := getAuctionInterval()

	go func() {
		ticker := time.NewTicker(checkInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				logger.Info("Auction close routine stopped")
				return
			case <-ticker.C:
				if err := ar.CloseExpiredAuctions(ctx, auctionInterval); err != nil {
					logger.Error("Error in auction close routine", err)
				}
			}
		}
	}()

	logger.Info(fmt.Sprintf("Auction close routine started - checkInterval: %v, auctionInterval: %v", checkInterval, auctionInterval))
}

func getAuctionCheckInterval() time.Duration {
	checkInterval := os.Getenv("AUCTION_CHECK_INTERVAL")
	duration, err := time.ParseDuration(checkInterval)
	if err != nil {
		return time.Second * 30 // Default to 30 seconds
	}
	return duration
}

func getAuctionInterval() time.Duration {
	auctionInterval := os.Getenv("AUCTION_INTERVAL")
	duration, err := time.ParseDuration(auctionInterval)
	if err != nil {
		return time.Minute * 5 // Default to 5 minutes
	}
	return duration
}
