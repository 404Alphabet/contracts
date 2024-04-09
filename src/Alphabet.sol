//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC404} from "./ERC404/ERC404.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Alphabet is ERC404 {
    string public dataURI;
    string public baseTokenURI;

    constructor(address _owner)
        ERC404("Alphabet", "ALPHABET", 18, 10000, _owner)
    {
        balanceOf[_owner] = 10000 * 10**18;
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        _setNameSymbol(_name, _symbol);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (bytes(baseTokenURI).length > 0) {
            return string.concat(baseTokenURI, Strings.toString(id));
        } else {
            uint16 seed = uint16(bytes2(keccak256(abi.encodePacked(id))));
            string memory image;
            string memory letter;

            // Calculate the segment index (0 to 25) based on the seed value
            uint256 segmentIndex = seed / 2520; // 65535 / 26 segments = 2520 per segment

            // Define arrays of letters and images
            string[26] memory letters = [
                "A",
                "B",
                "C",
                "D",
                "E",
                "F",
                "G",
                "H",
                "I",
                "J",
                "K",
                "L",
                "M",
                "N",
                "O",
                "P",
                "Q",
                "R",
                "S",
                "T",
                "U",
                "V",
                "W",
                "X",
                "Y",
                "Z"
            ];
            string[26] memory images = [
                "a.gif",
                "b.gif",
                "c.gif",
                "d.gif",
                "e.gif",
                "f.gif",
                "g.gif",
                "h.gif",
                "i.gif",
                "j.gif",
                "k.gif",
                "l.gif",
                "m.gif",
                "n.gif",
                "o.gif",
                "p.gif",
                "q.gif",
                "r.gif",
                "s.gif",
                "t.gif",
                "u.gif",
                "v.gif",
                "w.gif",
                "x.gif",
                "y.gif",
                "z.gif"
            ];

            // Use the segment index to select the letter and image
            if (segmentIndex < 26) {
                letter = letters[segmentIndex];
                image = images[segmentIndex];
            } else {
                // Handle unexpected case if segmentIndex somehow exceeds 25
                letter = "Z"; // Default/fallback letter
                image = "z.gif"; // Default/fallback image
            }

            string memory jsonPreImage = string.concat(
                string.concat(
                    string.concat('{"name": "Alphabet #', Strings.toString(id)),
                    '","description":"A collection of 10,000 replicants enabled by ERC404, an experimental token standard.","external_url":"https://404alphabet.xyz","image":"'
                ),
                string.concat(dataURI, image)
            );
            string memory jsonPostImage = string.concat(
                '","attributes":[{"trait_type":"Letter","value":"',
                letter
            );
            string memory jsonPostTraits = '"}]}';

            return
                string.concat(
                    "data:application/json;utf8,",
                    string.concat(
                        string.concat(jsonPreImage, jsonPostImage),
                        jsonPostTraits
                    )
                );
        }
    }
}
