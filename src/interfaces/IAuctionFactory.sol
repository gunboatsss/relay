// SPDX-License-Identifier: AGPL3.0
pragma solidity >=0.8.18 <0.9.0;

interface IAuctionFactory {
    function createNewAuction(
        address _want,
        address _hook,
        address _governance
    ) external returns (address);
}