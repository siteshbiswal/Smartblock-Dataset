// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Dours
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                    ╓╗╗╣╣╣╣╣╣╗╦                                                             //
//                  ╗╩╙╜└ ╠╔╩└╨╣╬╙╣╦                    ╗╗          ╔╗╣╣╣╗╥        ╓╓╥╗╗╣╥    //
//                      ─╩╓╣╦    ╚╦╫╗     ╓╣╣╝╨═╖     ╓╣╬        ╔└╣╣╬ ╙╜╬║─   ╔╣╣╣╣╣╩╙└      //
//               ┌─  ╔  ╪ ╣╣═     ╫╞╣─ ┌╓╣╣╩  └╫└╦  ╔╔╣╬     ┬╣═╒╕╣╣╣═   ╜╣╝─╣╣╜╙╙╙─          //
//           ╓╣╣╗╣╣╩╫┌╓╗╣╝╫╬      ╫╞╣═╔╔╣╩─    ║╦╣ ╛╫╣╩    ┌╓╣╝╔╒╣╣╣╝   ╗╣╨╛╫╣╓╓╓╓╓╓╓╓        //
//         ╙╟╣╨ ╗╣╧╫╬╙╥╣╫╝╟╩      ╝╣╣╕╔╣╩     ╓╟╣╬ ╫╣╬    ╔╗╣╜┌╬╣╣╣╬ ╓╣╣╨ ╒╬╫╣╣╣╝╩╜╬╜╫╣       //
//         ╛╣╩ ╗╣ ╛╣┐╔╬╫╣╝╣      ╨╫╣╣┌╣╣    ╔╓╣╣╨╔╔╣╣═   ┌╣╣╨┌╬╣╣╣╣╣╣╩╙    ╙╙     ╓╗╣╣╨       //
//         ─╙  ╚╬   ╦╣╬╬╫╣╛     ╓╣╣╣╝╞╣╣   ╓╣╣╩  ╬╫╣╣─ ╓╣╣╝ ┌╩╣╣╣╣╣╣╣╥         ╓╗╣╣╣╨         //
//                 ╒╒╬╣╣╣╣    ╓╣╣╣╣╩╚╗╚╣╣╗╣╣╣╙  ╒╕╣╣╣╣╣╣╬╣╣ ╣╟╣╣╣╩╣╣╣╣╦     ╥╣╣╣╣╩╙           //
//                 ┘╟╫╣╣╣╩  ╓╣╣╣╣╣╨  └╙╩╩╙╙     └╬╟╙║║║╜╨╙  ╣╟╣╣╩╘╦╟╣╣╣╣╥ ╣╬╙╨╙└              //
//                ╔╔╬╣╣╣╣ ╓╩╙╟╣╣╣╙                          └╙    ╙╣╬╝╬╝╣╣╥                   //
//                ╬╠╟╒╣╣╬╣╬╗╣╣╣╝                                     └ ╙╗╬╩╤                  //
//                ─╓┘╙╣╣╣╣╣╣╣╩─                                          └                    //
//                  └╫╣╙╝╩╜╙                                                                  //
//                                     byamara.com/thedours                                   //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract DOURS is ERC721Creator {
    constructor() ERC721Creator("The Dours", "DOURS") {}
}