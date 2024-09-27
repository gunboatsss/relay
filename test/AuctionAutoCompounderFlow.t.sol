// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./AuctionAutoCompounder.t.sol";
import {Auction} from "tokenized-strategy-periphery/src/Auctions/Auction.sol";

contract AuctionAutoCompounderFlow is AuctionAutoCompounderTest {
    uint256 public immutable PRECISION = 1e12;
    uint256 public immutable MAX_TIME = 4 * 365 * 86400;
    uint256 bribeToken = 1e6;
    uint256 bribeUSDC = 1e3; // low enough for liq testing

    function _createBribeWithAmount(BribeVotingReward _bribeVotingReward, address _token, uint256 _amount) internal {
        IERC20(_token).approve(address(_bribeVotingReward), _amount);
        _bribeVotingReward.notifyRewardAmount(address(_token), _amount);
    }

    function _createFeesWithAmount(FeesVotingReward _feesVotingReward, address _token, uint256 _amount) internal {
        deal(_token, address(gauge), _amount);
        vm.startPrank(address(gauge));
        IERC20(_token).approve(address(_feesVotingReward), _amount);
        _feesVotingReward.notifyRewardAmount(address(_token), _amount);
        vm.stopPrank();
    }

    function testClaimBribesAndCompound() public {
        address[] memory pools = new address[](1);
        uint256[] memory weights = new uint256[](1);
        address[] memory rewards = new address[](3);
        pools[0] = address(pool);
        weights[0] = 10000;
        rewards[0] = address(DAI);
        rewards[1] = address(USDC);
        rewards[2] = address(FRAX);

        bribes.push(address(bribeVotingReward));
        tokensToClaim.push(rewards);

        // Epoch 0: DAI bribed => voted for DAI bribe
        // Epoch 1: DAI bribed => passive vote
        // Epoch 2: Accrued DAI claimed & compounded => FRAX & USDC bribed => poked
        // Epoch 3: USDC claimed & compounded => USDC bribed => passive vote
        // Epoch 4: DAI & USDC bribed => FRAX claimed & compounded => poked
        // Epoch 5: FRAX & USDC bribed => passive vote
        // Epoch 6: FRAX, DAI, & Accrued USDC claimed

        // Epoch 0

        _createBribeWithAmount(bribeVotingReward, address(DAI), bribeToken);
        auctionAutoCompounder.vote(pools, weights);
        skipToNextEpoch(1);

        // Epoch 1

        _createBribeWithAmount(bribeVotingReward, address(DAI), bribeToken);
        skipToNextEpoch(6 days + 1);

        // Epoch 2

        assertEq(DAI.balanceOf(address(bribeVotingReward)), bribeToken * 2);
        uint256 preNFTBalance = escrow.balanceOfNFT(mTokenId);
        uint256 preCallerVELO = VELO.balanceOf(address(owner2));

        uint256 slippage = 500;
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimBribes, (bribes, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(DAI), slippage, new IRouter.Route[](0))
        );
        calls[2] = abi.encodeWithSelector(auctionAutoCompounder.rewardAndCompound.selector);
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(DAI.balanceOf(address(bribeVotingReward)), 0);
        assertEq(DAI.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        _createBribeWithAmount(bribeVotingReward, address(FRAX), bribeToken);
        _createBribeWithAmount(bribeVotingReward, address(USDC), bribeUSDC);
        voter.poke(mTokenId);
        skipToNextEpoch(6 days + 1);

        // Epoch 3

        assertEq(USDC.balanceOf(address(bribeVotingReward)), bribeUSDC);
        assertEq(FRAX.balanceOf(address(bribeVotingReward)), bribeToken);
        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        tokensToClaim = new address[][](1);
        tokensToClaim[0] = [address(USDC)];
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimBribes, (bribes, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(USDC), slippage, new IRouter.Route[](0))
        );
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(USDC.balanceOf(address(bribeVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(bribeVotingReward)), bribeToken);
        assertEq(USDC.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        _createBribeWithAmount(bribeVotingReward, address(USDC), bribeUSDC);
        skipToNextEpoch(6 days + 1);

        // Epoch 4

        _createBribeWithAmount(bribeVotingReward, address(DAI), bribeToken);
        _createBribeWithAmount(bribeVotingReward, address(USDC), bribeUSDC);

        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        tokensToClaim[0] = [address(FRAX)];
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimBribes, (bribes, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(FRAX), slippage, new IRouter.Route[](0))
        );
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(DAI.balanceOf(address(bribeVotingReward)), bribeToken);
        assertEq(USDC.balanceOf(address(bribeVotingReward)), bribeUSDC * 2);
        assertEq(FRAX.balanceOf(address(bribeVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        voter.poke(mTokenId);
        skipToNextEpoch(6 days + 1);

        // Epoch 5

        _createBribeWithAmount(bribeVotingReward, address(FRAX), bribeToken);
        _createBribeWithAmount(bribeVotingReward, address(USDC), bribeUSDC);
        skipToNextEpoch(6 days + 1);

        assertEq(DAI.balanceOf(address(bribeVotingReward)), bribeToken);
        assertEq(USDC.balanceOf(address(bribeVotingReward)), bribeUSDC * 3);
        assertEq(FRAX.balanceOf(address(bribeVotingReward)), bribeToken);

        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        tokensToClaim[0] = [address(DAI), address(USDC), address(FRAX)];
        calls = new bytes[](5);
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimBribes, (bribes, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(DAI), slippage, new IRouter.Route[](0))
        );
        calls[2] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(FRAX), slippage, new IRouter.Route[](0))
        );
        calls[3] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(USDC), slippage, new IRouter.Route[](0))
        );
        calls[4] = abi.encodeWithSelector(auctionAutoCompounder.rewardAndCompound.selector);
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(DAI.balanceOf(address(bribeVotingReward)), 0);
        assertEq(USDC.balanceOf(address(bribeVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(bribeVotingReward)), 0);
        assertEq(DAI.balanceOf(address(auctionAutoCompounder)), 0);
        assertEq(USDC.balanceOf(address(auctionAutoCompounder)), 0);
        assertEq(FRAX.balanceOf(address(auctionAutoCompounder)), 0);
        assertEq(VELO.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);
    }

    function testClaimFeesAndCompound() public {
        address[] memory pools = new address[](1);
        uint256[] memory weights = new uint256[](1);
        address[] memory rewards = new address[](3);
        pools[0] = address(pool);
        weights[0] = 10000;
        rewards[0] = address(USDC);
        rewards[1] = address(FRAX);

        fees.push(address(feesVotingReward));
        tokensToClaim.push(rewards);

        // Epoch 0: FRAX fees => voted for FRAX fees
        // Epoch 1: FRAX fees => passive vote
        // Epoch 2: Accrued FRAX claimed & compounded => FRAX & USDC fees => poked
        // Epoch 3: USDC claimed & compounded => USDC fees => passive vote
        // Epoch 4: FRAX & USDC fees => FRAX claimed & compounded => poked
        // Epoch 5: FRAX & USDC fees => passive vote
        // Epoch 6: FRAX & Accrued USDC claimed

        // Epoch 0

        _createFeesWithAmount(feesVotingReward, address(FRAX), bribeToken);
        auctionAutoCompounder.vote(pools, weights);
        skipToNextEpoch(1);

        // Epoch 1

        _createFeesWithAmount(feesVotingReward, address(FRAX), bribeToken);
        skipToNextEpoch(6 days + 1);

        // Epoch 2

        assertEq(FRAX.balanceOf(address(feesVotingReward)), bribeToken * 2);
        uint256 preNFTBalance = escrow.balanceOfNFT(mTokenId);
        uint256 preCallerVELO = VELO.balanceOf(address(owner2));

        uint256 slippage = 500;
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimFees, (fees, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(FRAX), slippage, new IRouter.Route[](0))
        );
        calls[2] = abi.encodeWithSelector(auctionAutoCompounder.rewardAndCompound.selector);
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(FRAX.balanceOf(address(feesVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        _createFeesWithAmount(feesVotingReward, address(FRAX), bribeToken);
        _createFeesWithAmount(feesVotingReward, address(USDC), bribeUSDC);
        voter.poke(mTokenId);
        skipToNextEpoch(6 days + 1);

        // Epoch 3

        assertEq(USDC.balanceOf(address(feesVotingReward)), bribeUSDC);
        assertEq(FRAX.balanceOf(address(feesVotingReward)), bribeToken);
        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        tokensToClaim = new address[][](1);
        tokensToClaim[0] = [address(USDC)];
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimFees, (fees, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(USDC), slippage, new IRouter.Route[](0))
        );
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(USDC.balanceOf(address(feesVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(feesVotingReward)), bribeToken);
        assertEq(USDC.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        _createFeesWithAmount(feesVotingReward, address(USDC), bribeUSDC);
        skipToNextEpoch(6 days + 1);

        // Epoch 4

        _createFeesWithAmount(feesVotingReward, address(FRAX), bribeToken);
        _createFeesWithAmount(feesVotingReward, address(USDC), bribeUSDC);

        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        tokensToClaim[0] = [address(FRAX)];
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimFees, (fees, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(FRAX), slippage, new IRouter.Route[](0))
        );
        vm.prank(address(owner2));
        auctionAutoCompounder.multicall(calls);

        assertEq(FRAX.balanceOf(address(feesVotingReward)), bribeToken);
        assertEq(USDC.balanceOf(address(feesVotingReward)), bribeUSDC * 2);
        assertEq(FRAX.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);

        voter.poke(mTokenId);
        skipToNextEpoch(6 days + 1);

        // Epoch 5

        _createFeesWithAmount(feesVotingReward, address(FRAX), bribeToken);
        _createFeesWithAmount(feesVotingReward, address(USDC), bribeUSDC);
        skipToNextEpoch(6 days + 1);

        assertEq(FRAX.balanceOf(address(feesVotingReward)), bribeToken * 2);
        assertEq(USDC.balanceOf(address(feesVotingReward)), bribeUSDC * 3);

        preNFTBalance = escrow.balanceOfNFT(mTokenId);
        preCallerVELO = VELO.balanceOf(address(owner2));

        vm.prank(address(owner2));
        tokensToClaim[0] = [address(FRAX), address(USDC)];
        calls = new bytes[](4);
        calls[0] = abi.encodeCall(auctionAutoCompounder.claimFees, (fees, tokensToClaim));
        calls[1] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(FRAX), slippage, new IRouter.Route[](0))
        );
        calls[2] = abi.encodeCall(
            auctionAutoCompounder.swapTokenToVELOWithOptionalRoute,
            (address(USDC), slippage, new IRouter.Route[](0))
        );
        calls[3] = abi.encodeWithSelector(auctionAutoCompounder.rewardAndCompound.selector);
        auctionAutoCompounder.multicall(calls);

        assertEq(FRAX.balanceOf(address(feesVotingReward)), 0);
        assertEq(USDC.balanceOf(address(feesVotingReward)), 0);
        assertEq(FRAX.balanceOf(address(auctionAutoCompounder)), 0);
        assertEq(USDC.balanceOf(address(auctionAutoCompounder)), 0);
        assertEq(VELO.balanceOf(address(auctionAutoCompounder)), 0);
        assertGt(VELO.balanceOf(address(owner2)), preCallerVELO);
        assertGt(escrow.balanceOfNFT(mTokenId), preNFTBalance);
    }

    function testAuction() public {
        deal(address(DAI), address(auctionAutoCompounder), 1e18 * 1e9);
        skipToNextEpoch(1 days);
        assertFalse(auctionAutoCompounder.disabled(address(DAI)));
        auctionAutoCompounder.enable(address(DAI));
        Auction auction = Auction(address(auctionAutoCompounder.AUCTION()));
        bytes32 auctionId = auction.getAuctionId(address(DAI));
        assertTrue(auction.kickable(auctionId) == 1e18*1e9);
        auction.kick(auctionId);
        skip(20 hours);
        uint256 getAmountNeeded = auction.getAmountNeeded(auctionId, 1e18*1e9);
        address bidder = address(6666666);
        deal(address(VELO), bidder, getAmountNeeded);
        vm.startPrank(bidder);
        VELO.approve(address(auction), type(uint256).max);
        auction.take(auctionId);
    }
}
