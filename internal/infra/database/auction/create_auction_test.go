package auction

import (
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestGetAuctionIntervalWithEnvVar(t *testing.T) {
	t.Run("should return configured interval when env var is set", func(t *testing.T) {
		// Arrange
		os.Setenv("AUCTION_INTERVAL", "2m")
		defer os.Unsetenv("AUCTION_INTERVAL")

		// Act
		interval := getAuctionInterval()

		// Assert
		assert.Equal(t, time.Minute*2, interval)
	})
}

func TestGetAuctionInterval(t *testing.T) {
	t.Run("should return default interval when env var is not set", func(t *testing.T) {
		// Act
		interval := getAuctionInterval()

		// Assert
		assert.Equal(t, time.Minute*5, interval)
	})
}

func TestGetAuctionCheckInterval(t *testing.T) {
	t.Run("should return default check interval when env var is not set", func(t *testing.T) {
		// Act
		interval := getAuctionCheckInterval()

		// Assert
		assert.Equal(t, time.Second*30, interval)
	})
}
