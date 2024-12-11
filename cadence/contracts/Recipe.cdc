import "TopShot"
import "NonFungibleToken"

access(all) contract Recipe {
    // This is a snippet extracting the relevant logic from the TopShot contract for demonstration purposes
    // More TopShot Code Above

    // Emitted when a Moment is minted from a Set
    access(all) event MomentMinted(momentID: UInt64, playID: UInt32, setID: UInt32, serialNumber: UInt32, subeditionID: UInt32)

    access(all)
    resource Set {
        access(contract) var retired: {UInt32: Bool}
        access(all) let setID: UInt32
        access(contract) var numberMintedPerPlay: {UInt32: UInt32}

        init(name: String) {
            self.setID = TopShot.nextSetID
            self.numberMintedPerPlay = {}
            self.retired = {}
        }

        // mintMoment mints a new Moment and returns the newly minted Moment
        // 
        // Parameters: playID: The ID of the Play that the Moment references
        //
        // Pre-Conditions:
        // The Play must exist in the Set and be allowed to mint new Moments
        //
        // Returns: The NFT that was minted
        // 
        access(all) fun mintMoment(playID: UInt32): @NFT {
            pre {
                self.retired[playID] != nil: "Cannot mint the moment: This play doesn't exist."
                !self.retired[playID]!: "Cannot mint the moment from this play: This play has been retired."
            }

            // Gets the number of Moments that have been minted for this Play
            // to use as this Moment's serial number
            let numInPlay = self.numberMintedPerPlay[playID]!

            // Mint the new moment
            let newMoment: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1),
                                              playID: playID,
                                              setID: self.setID,
                                              subeditionID: 0)

            // Increment the count of Moments minted for this Play
            self.numberMintedPerPlay[playID] = numInPlay + UInt32(1)

            return <-newMoment
        }

        // batchMintMoment mints an arbitrary quantity of Moments 
        // and returns them as a Collection
        //
        // Parameters: playID: the ID of the Play that the Moments are minted for
        //             quantity: The quantity of Moments to be minted
        //
        // Returns: Collection object that contains all the Moments that were minted
        //
        access(all)
        fun batchMintMoment(playID: UInt32, quantity: UInt64): @TopShot.Collection {
            let newCollection <- create TopShot.Collection()
            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <-self.mintMoment(playID: playID))
                i = i + UInt64(1)
            }

            return <-newCollection
        }
    }

    access(all)
    struct MomentData {

        // The ID of the Set that the Moment comes from
        access(all) let setID: UInt32

        // The ID of the Play that the Moment references
        access(all) let playID: UInt32

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        access(all) let serialNumber: UInt32

        init(setID: UInt32, playID: UInt32, serialNumber: UInt32) {
            self.setID = setID
            self.playID = playID
            self.serialNumber = serialNumber
        }

    }

    // The resource that represents the Moment NFTs
    //
    access(all)
    resource NFT: NonFungibleToken.INFT {

        // Global unique moment ID
        access(all)
        let id: UInt64
        
        // Struct of Moment metadata
        access(all)
        let data: MomentData

        access(all) var totalSupply: UInt64

        init(serialNumber: UInt32, playID: UInt32, setID: UInt32, subeditionID: UInt32) {
            // Increment the global Moment IDs
            self.totalSupply = TopShot.totalSupply + UInt64(1)
            self.id = TopShot.totalSupply

            // Set the metadata struct
            self.data = MomentData(setID: setID, playID: playID, serialNumber: serialNumber)

            emit MomentMinted(momentID: self.id,
                              playID: playID,
                              setID: self.data.setID,
                              serialNumber: self.data.serialNumber,
                              subeditionID: subeditionID)
        }

    }

    // More TopShot Code Below
}