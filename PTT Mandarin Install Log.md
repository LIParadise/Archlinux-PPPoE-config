最近剛好也在弄Archlinux上面連線種花PPPoE的事情，就順便紀錄一下好了

嗯雖然基本上就是照抄Archlinux Wiki…

事前準備：
- 能動的種花浮動ip
- "By the way I use Arch"通行證
- `systemd`

1. 安裝`ppp`這個package，按照`ppp`的Archlinux Wiki在`/etc/ppp/peers`底下寫自己需要的連線設定檔
  個人額外設定了`lcp-echo-interval`、`lcp-echo-failure`、以及`holdoff`等判斷斷線與否/重連方式等的設定
  以下討論假定設定檔為`/etc/ppp/peers/dsl_provider`
2. 同樣依照`ppp`的Arch Wiki頁面指示，在`/etc/ppp/chap-secrets`寫入PPPoE連線資訊。因為種花是種花，所以可能`pap-secrets`也要寫；個人是沒有後者就連不上，猜測是種花目前還是採pap方式認證的緣故
3. `pppd call dsl_provider`嘗試連線。如果`ip link`指令有`ppp0`之類的新介面出現的話代表應該已經連線成功，若否則可以照Wiki指示，用`journalctl -b --no-pager | grep ppp`查看錯誤原因
  而若已經有了新的`ppp0`之類字眼的介面，但是主機顯示的ip仍然不是種花的固定ip時，可以確認`ip route`看看目前的routing是否有把該介面當作預設；在`dsl_provider`裡加入`defaultroute`可以在`pppd call dsl_provider`時固定將該次PPPoE虛擬介面作為預設routing (*)
4. 如果需要開機自動連線，建立`/etc/ppp/peers/dsl`資料夾，在其中建立一個`provider`軟連結連到`/etc/ppp/peers/dsl_provider`，而後`systemctl enable ppp@dsl_provider`啟用daemon
5. `poff -a`可以關掉目前所有PPPoE連線

如果沒什麼大問題的話，至此應該有了可以動、可以關掉的種花PPPoE固定IP連線了。接下來談幾個可能會出現的問題

1. `ip route`裡`ppp0`前面有default字樣，但是外部看到的IP仍然不是種花給的IP，並且`ip route`給出來的資料不只有一行有前綴`default`
  linux下routing是看定義的先後順序以及metric值(0~100，default=0)決定的，metric小則優先，metric同則先定義者優先。因此若原本的浮動IP連線之類就已經有一個`default`卡著的話，需要用`ip route del default`之類的刪掉之，而後視需求重新加回
  如果是其他發行版的話，`ppp`可能會有額外的模組，可以直接在`dsl_provider`設定檔內加入`replacedefaultroute`選項，如此在PPPoE連線成功後，daemon會幫你踢掉原本的default連線。
  可惜的是，Archlinux的`ppp`沒有編入這個選項的支援，因此需要使用其他腳本解決；按照wiki指示，建立`/etc/ppp/ip-pre-up`、`/etc/ppp/ip-pre-up.d/`，然後在其下放腳本處理之
2. `networkmanager`的`nmcli`看不到這個PPPoE連線
  只玩過單用`ppp`完成PPPoE，這部份我也不清楚怎麼弄出來，要看樓上那篇之類的@@
  總之`ip`指令確定是相容的
3. `defaultroute`沒有`metric`設定選項，預設的0有些過強
  這部份我是弄了個腳本解決
  因為平常還會用到VPN的關係，而該工具預設的metric在50，所以才有了腳本裡60這個數字
  大致上是在PPPoE連線建立後刪掉所有default route，然後把個人會用到的vpn以及PPPoE加回來

