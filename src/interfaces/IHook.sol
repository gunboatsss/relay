// SPDX-License-Identifier: AGPL3.0
pragma solidity >=0.8.0 <0.9.0;
/// @notice Interface that the optional `hook` contract should implement if the non-standard logic is desired.
interface IHook {
    function kickable(address _fromToken) external view returns (uint256);

    function auctionKicked(address _fromToken) external returns (uint256);

    function preTake(
        address _fromToken,
        uint256 _amountToTake,
        uint256 _amountToPay
    ) external;

    function postTake(
        address _toToken,
        uint256 _amountTaken,
        uint256 _amountPayed
    ) external;
}