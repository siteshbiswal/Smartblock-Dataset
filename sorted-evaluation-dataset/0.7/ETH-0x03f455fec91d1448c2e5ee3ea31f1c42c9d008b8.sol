// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: soulcurryart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//       _____             _    _____                                      _       //
//      / ____|           | |  / ____|                          /\        | |      //
//     | (___   ___  _   _| | | |    _   _ _ __ _ __ _   _     /  \   _ __| |_     //
//      \___ \ / _ \| | | | | | |   | | | | '__| '__| | | |   / /\ \ | '__| __|    //
//      ____) | (_) | |_| | | | |___| |_| | |  | |  | |_| |  / ____ \| |  | |_     //
//     |_____/ \___/ \__,_|_|  \_____\__,_|_|  |_|   \__, | /_/    \_\_|   \__|    //
//                                                    __/ |                        //
//                                                   |___/                         //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("soulcurryart", "ETH") {}
}