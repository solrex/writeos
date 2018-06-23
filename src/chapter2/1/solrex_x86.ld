/* chapter2/1/solrex_x86.ld

   Author: Wenbo Yang <http://yangwenbo.com>

   This file is part of the source code of book "Write Your Own OS with Free
   and Open Source Software". Homepage @ <https://github.com/solrex/writeos>.

   This file is licensed under the GNU General Public License; either
   version 3 of the License, or (at your option) any later version. */

SECTIONS
{
  . = 0x7c00;
  .text :
  {
    _ftext = .;     /* Program will be loaded to 0x7c00. */
  } = 0
}
