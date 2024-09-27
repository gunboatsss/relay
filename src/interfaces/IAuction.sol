// SPDX-License-Identifier: AGPL3.0
pragma solidity >=0.8.19 <0.9.0;

interface IAuction {
    struct TokenInfo {
        address tokenAddress;
        uint96 scaler;
    }

    struct AuctionInfo {
        TokenInfo fromInfo;
        uint96 kicked;
        address receiver;
        uint128 initialAvailable;
        uint128 currentAvailable;
    }

    function auctions(bytes32 _auctionId) external view returns (AuctionInfo memory);

    function enable(address _from) external returns (bytes32);

    function disable(address _from) external;
}